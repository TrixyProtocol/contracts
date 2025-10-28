import "TrixyTypes"
import "TrixyEvents"
import "Market"

access(all) contract TrixyProtocol {
    
    access(all) let MarketManagerStoragePath: StoragePath
    access(all) let MarketManagerPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    access(all) var totalMarkets: UInt64
    access(all) var protocolFee: UFix64
    access(all) var feeRecipient: Address
    
    access(all) resource MarketManager {
        access(self) let markets: @{UInt64: Market.MarketResource}
        
        init() {
            self.markets <- {}
        }
        
        access(all) fun createMarket(question: String, endTime: UFix64, options: [String], yieldProtocol: String): UInt64 {
            let marketId = TrixyProtocol.totalMarkets
            TrixyProtocol.totalMarkets = TrixyProtocol.totalMarkets + 1
            
            let market <- Market.createMarket(
                id: marketId,
                question: question,
                endTime: endTime,
                options: options,
                yieldProtocol: yieldProtocol,
                creator: self.owner!.address,
                protocolFee: TrixyProtocol.protocolFee
            )
            
            TrixyEvents.emitMarketCreated(marketId: marketId, question: question, endTime: endTime, options: options, yieldProtocol: yieldProtocol, creator: self.owner!.address)
            
            self.markets[marketId] <-! market
            return marketId
        }
        
        access(all) fun borrowMarket(marketId: UInt64): &Market.MarketResource? {
            return &self.markets[marketId]
        }
        
        access(all) fun getMarketIds(): [UInt64] {
            return self.markets.keys
        }
    }
    
    access(all) resource Admin {
        access(all) fun setProtocolFee(newFee: UFix64) {
            pre { newFee <= 0.1: "Fee cannot exceed 10%" }
            TrixyProtocol.protocolFee = newFee
        }
        
        access(all) fun setFeeRecipient(newRecipient: Address) {
            TrixyProtocol.feeRecipient = newRecipient
        }
    }
    
    access(all) fun createMarketManager(): @MarketManager {
        return <- create MarketManager()
    }
    
    init() {
        self.MarketManagerStoragePath = /storage/TrixyMarketManager
        self.MarketManagerPublicPath = /public/TrixyMarketManager
        self.AdminStoragePath = /storage/TrixyAdmin
        
        self.totalMarkets = 0
        self.protocolFee = 0.02
        self.feeRecipient = self.account.address
        
        self.account.storage.save(<- create Admin(), to: self.AdminStoragePath)
    }
}
