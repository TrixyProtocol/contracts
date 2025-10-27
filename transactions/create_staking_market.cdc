import "TrixyProtocol"

/// Create a new prediction market with yield generation
///
/// Examples:
/// - "Will Bitcoin reach $100k by EOY?" options: ["YES", "NO"], yieldProtocol: "aave"
/// - "Will Elon release Tesla phone?" options: ["YES", "NO"], yieldProtocol: "morpho"
/// - "Which team wins?" options: ["Team A", "Team B"], yieldProtocol: "compound"
///
transaction(question: String, endTime: UFix64, options: [String], yieldProtocol: String) {
    
    let manager: auth(Storage) &TrixyProtocol.MarketManager
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Borrow or create MarketManager
        if signer.storage.borrow<&TrixyProtocol.MarketManager>(
            from: TrixyProtocol.MarketManagerStoragePath
        ) == nil {
            let manager <- TrixyProtocol.createMarketManager()
            signer.storage.save(<-manager, to: TrixyProtocol.MarketManagerStoragePath)
            
            let cap = signer.capabilities.storage.issue<&TrixyProtocol.MarketManager>(
                TrixyProtocol.MarketManagerStoragePath
            )
            signer.capabilities.publish(cap, at: TrixyProtocol.MarketManagerPublicPath)
        }
        
        self.manager = signer.storage.borrow<auth(Storage) &TrixyProtocol.MarketManager>(
            from: TrixyProtocol.MarketManagerStoragePath
        )!
    }
    
    execute {
        let marketId = self.manager.createMarket(
            question: question,
            endTime: endTime,
            options: options,
            yieldProtocol: yieldProtocol
        )
        
        log("Prediction market created with ID: ".concat(marketId.toString()))
        log("Question: ".concat(question))
        log("Options: ".concat(options.length.toString()))
        log("Yield Protocol: ".concat(yieldProtocol))
    }
}
