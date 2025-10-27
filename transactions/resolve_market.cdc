import "TrixyProtocol"

/// Resolve prediction market with winning option
///
/// @param marketId: ID of the market to resolve
/// @param winningOption: The winning outcome (e.g., "YES", "NO", "Team A")
///
/// Example: "YES" for a "Will Bitcoin reach $100k?" market
///
transaction(marketId: UInt64, winningOption: String) {
    
    let manager: auth(Storage) &TrixyProtocol.MarketManager
    
    prepare(signer: auth(Storage) &Account) {
        self.manager = signer.storage.borrow<auth(Storage) &TrixyProtocol.MarketManager>(
            from: TrixyProtocol.MarketManagerStoragePath
        ) ?? panic("Could not borrow MarketManager")
    }
    
    execute {
        let market = self.manager.borrowMarket(marketId: marketId)
            ?? panic("Market not found")
        
        market.resolveMarket(winningOption: winningOption)
        
        log("Market resolved successfully!")
        log("Market ID: ".concat(marketId.toString()))
        log("Winning Option: ".concat(winningOption))
    }
}
