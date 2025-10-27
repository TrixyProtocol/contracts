import "FungibleToken"
import "FlowToken"
import "TrixyProtocol"
import "Market"

/// Transaction to setup FlowActions connectors on an existing market
/// This enables composable DeFi operations using Source/Sink patterns
///
/// @param marketAddress: Address where the market is stored
/// @param marketId: ID of the market to configure
/// @param maxBalance: Optional maximum balance for the yield vault (nil for unlimited)
///
transaction(marketAddress: Address, marketId: UInt64, maxBalance: UFix64?) {
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Borrow the market from the protocol
        let protocolRef = getAccount(marketAddress)
            .capabilities
            .borrow<&TrixyProtocol.MarketManager>(TrixyProtocol.MarketManagerPublicPath)
            ?? panic("Could not borrow protocol reference")
        
        let marketRef = protocolRef.borrowMarket(marketId: marketId)
            ?? panic("Market not found")
        
        // Get capability to the market's yield vault
        // Note: In production, this would need proper capability setup
        // For now, we'll use the signer's FlowToken vault as example
        let vaultPath = /storage/flowTokenVault
        
        // Get withdraw capability for the vault
        let vaultCap = signer.capabilities
            .storage
            .issue<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(vaultPath)
        
        // Setup FlowActions connectors
        marketRef.setupFlowActionsConnectors(
            vaultCap: vaultCap,
            maxBalance: maxBalance
        )
        
        let status = marketRef.getFlowActionsStatus()
        log("FlowActions connectors configured for market ".concat(marketId.toString()))
    }
}
