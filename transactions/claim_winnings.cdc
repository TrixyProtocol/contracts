import "TrixyProtocol"
import "FungibleToken"
import "FlowToken"

/// Claim winnings from a resolved market
///
/// @param marketCreator: Address of the market creator (who holds the MarketManager)
/// @param marketId: ID of the market
///
transaction(marketCreator: Address, marketId: UInt64) {
    
    let manager: &TrixyProtocol.MarketManager
    let receiver: &FlowToken.Vault
    let signerAddress: Address
    
    prepare(signer: auth(Storage) &Account) {
        self.signerAddress = signer.address
        
        // Get MarketManager from market creator
        self.manager = getAccount(marketCreator).capabilities
            .borrow<&TrixyProtocol.MarketManager>(TrixyProtocol.MarketManagerPublicPath)
            ?? panic("Could not borrow MarketManager")
        
        // Get receiver vault
        self.receiver = signer.storage.borrow<&FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault")
    }
    
    execute {
        let market = self.manager.borrowMarket(marketId: marketId)
            ?? panic("Market not found")
        
        let payout <- market.claimWinnings(user: self.signerAddress)
        let amount = payout.balance
        
        self.receiver.deposit(from: <-payout)
        
        log("Winnings claimed successfully!")
        log("Amount: ".concat(amount.toString()).concat(" FLOW"))
    }
}
