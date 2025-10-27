import "FungibleToken"
import "FlowToken"
import "IStakingProtocol"
import "PriceOracle"

access(all) contract FigmentAdapter: IStakingProtocol {
    
    access(all) let positions: {String: UFix64}
    access(self) var nextPositionId: UInt64
    access(self) var mockAPY: UFix64
    
    access(all) fun stake(vault: @FlowToken.Vault): String {
        let amount = vault.balance
        let positionId = "figment_".concat(self.nextPositionId.toString())
        self.nextPositionId = self.nextPositionId + 1
        
        self.positions[positionId] = amount
        
        destroy vault
        
        return positionId
    }
    
    access(all) fun unstake(amount: UFix64, positionId: String): @FlowToken.Vault {
        pre {
            self.positions[positionId] != nil: "Position not found"
            self.positions[positionId]! >= amount: "Insufficient balance"
        }
        
        self.positions[positionId] = self.positions[positionId]! - amount
        
        return <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
    }
    
    access(all) fun getCurrentAPY(): UFix64 {
        return PriceOracle.calculateAPY(protocol: "figment")
    }
    
    access(all) fun getBalance(positionId: String): UFix64 {
        return self.positions[positionId] ?? 0.0
    }
    
    access(all) fun getProtocolName(): String {
        return "Figment"
    }
    
    access(all) fun getProtocolType(): UInt8 {
        return 2 
    }
    
    access(all) fun setMockAPY(apy: UFix64) {
        self.mockAPY = apy
    }
    
    init() {
        self.positions = {}
        self.nextPositionId = 0
        self.mockAPY = 11.8 
    }
}
