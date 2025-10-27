import "DeFiActions"
import "BandOracleConnectors"

access(all) contract PriceOracle {
    
    access(all) let OracleConfigStoragePath: StoragePath
    access(all) let AdminStoragePath: StoragePath
    
    access(all) var flowPrice: UFix64
    access(all) var lastPriceUpdate: UFix64
    
    access(all) struct ProtocolAPY {
        access(all) let protocol: String
        access(all) let apy: UFix64
        access(all) let price: UFix64
        access(all) let timestamp: UFix64
        
        init(protocol: String, apy: UFix64, price: UFix64, timestamp: UFix64) {
            self.protocol = protocol
            self.apy = apy
            self.price = price
            self.timestamp = timestamp
        }
    }
    
    access(all) event APYCalculated(protocol: String, apy: UFix64, price: UFix64, timestamp: UFix64)
    access(all) event PriceUpdated(oldPrice: UFix64, newPrice: UFix64, updater: Address, timestamp: UFix64)
    
    access(all) fun calculateAPY(protocol: String): UFix64 {
        
        let flowPrice = self.getFlowPrice()
        
        let apy = self.getBaseAPY(protocol: protocol, flowPrice: flowPrice)
        
        emit APYCalculated(
            protocol: protocol,
            apy: apy,
            price: flowPrice,
            timestamp: getCurrentBlock().timestamp
        )
        
        return apy
    }
    
    access(all) fun getFlowPrice(): UFix64 {
        return self.flowPrice
    }
    
    access(all) fun getBaseAPY(protocol: String, flowPrice: UFix64): UFix64 {
        
        let baseRates: {String: UFix64} = {
            "ankr": 12.5,
            "increment": 15.3,
            "figment": 10.8
        }
        
        let baseAPY = baseRates[protocol] ?? 10.0
        let priceImpact = 1.0 + (1.0 - flowPrice)
        let adjustedAPY = baseAPY * priceImpact
        
        if adjustedAPY < 5.0 {
            return 5.0
        } else if adjustedAPY > 50.0 {
            return 50.0
        }
        
        return adjustedAPY
    }
    
    access(all) fun getAllAPYs(): {String: UFix64} {
        let flowPrice = self.getFlowPrice()
        
        return {
            "ankr": self.getBaseAPY(protocol: "ankr", flowPrice: flowPrice),
            "increment": self.getBaseAPY(protocol: "increment", flowPrice: flowPrice),
            "figment": self.getBaseAPY(protocol: "figment", flowPrice: flowPrice)
        }
    }
    
    access(all) fun getBestProtocol(): String {
        let apys = self.getAllAPYs()
        
        var bestProtocol = "increment"
        var bestAPY: UFix64 = 0.0
        
        for protocol in apys.keys {
            let apy = apys[protocol]!
            if apy > bestAPY {
                bestAPY = apy
                bestProtocol = protocol
            }
        }
        
        return bestProtocol
    }
    
    access(all) fun calculateYield(principal: UFix64, apy: UFix64, durationSeconds: UFix64): UFix64 {
        
        let secondsPerYear: UFix64 = 31536000.0
        let years = durationSeconds / secondsPerYear
        
        let yield = principal * (apy / 100.0) * years
        
        return yield
    }
    
    access(all) fun calculateProjectedPayout(
        stakedAmount: UFix64,
        protocol: String,
        marketDuration: UFix64
    ): UFix64 {
        let apy = self.calculateAPY(protocol: protocol)
        let yield = self.calculateYield(
            principal: stakedAmount,
            apy: apy,
            durationSeconds: marketDuration
        )
        
        return stakedAmount + yield
    }
    
    access(all) resource Admin {
        
        access(all) fun updateFlowPrice(newPrice: UFix64) {
            pre {
                newPrice > 0.0: "Price must be positive"
                newPrice < 100.0: "Price seems unrealistic"
            }
            
            let oldPrice = PriceOracle.flowPrice
            PriceOracle.flowPrice = newPrice
            PriceOracle.lastPriceUpdate = getCurrentBlock().timestamp
            
            emit PriceUpdated(
                oldPrice: oldPrice,
                newPrice: newPrice,
                updater: self.owner!.address,
                timestamp: getCurrentBlock().timestamp
            )
        }
    }
    
    access(all) fun createAdmin(): @Admin {
        return <- create Admin()
    }
    
    init() {
        self.OracleConfigStoragePath = /storage/TrixyPriceOracle
        self.AdminStoragePath = /storage/TrixyPriceOracleAdmin
        
        self.flowPrice = 0.85  
        self.lastPriceUpdate = getCurrentBlock().timestamp
        
        self.account.storage.save(<- create Admin(), to: self.AdminStoragePath)
    }
}
