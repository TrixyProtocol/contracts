import "TrixyProtocol"
import "FungibleToken"
import "FlowToken"

/// Place a bet on a prediction market option
///
/// @param marketCreator: Address of the market creator
/// @param marketId: ID of the market
/// @param option: Option to bet on ("YES", "NO", "Team A", etc.)
/// @param amount: Amount of FLOW to bet
///
transaction(marketCreator: Address, marketId: UInt64, option: String, amount: UFix64) {
    
    let manager: &TrixyProtocol.MarketManager
    let payment: @FlowToken.Vault
    let signerAddress: Address
    
    prepare(signer: auth(Storage) &Account) {
        self.signerAddress = signer.address
        
        // Get MarketManager capability from market creator
        self.manager = getAccount(marketCreator).capabilities.borrow<&TrixyProtocol.MarketManager>(
            TrixyProtocol.MarketManagerPublicPath
        ) ?? panic("Could not borrow MarketManager from market creator")
        
        // Withdraw FLOW tokens for bet
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow FlowToken.Vault")
        
        self.payment <- vaultRef.withdraw(amount: amount) as! @FlowToken.Vault
    }
    
    execute {
        let market = self.manager.borrowMarket(marketId: marketId)
            ?? panic("Market not found")
        
        market.placeBet(
            user: self.signerAddress,
            option: option,
            payment: <-self.payment,
            protocolFee: 0.02
        )
        
        log("Bet placed successfully!")
        log("Market: ".concat(marketId.toString()))
        log("Option: ".concat(option))
        log("Amount: ".concat(amount.toString()))
    }
}
