import "PriceOracle"

/// Update FLOW price in PriceOracle (admin only)
/// This transaction is called by the cron job to update prices from external APIs
///
/// @param newPrice: New FLOW price in USD (e.g., 0.85 for $0.85)
///
transaction(newPrice: UFix64) {
    
    prepare(signer: auth(Storage) &Account) {
        // Borrow admin resource
        let admin = signer.storage.borrow<&PriceOracle.Admin>(
            from: PriceOracle.AdminStoragePath
        ) ?? panic("Could not borrow admin resource")
        
        // Update price
        admin.updateFlowPrice(newPrice: newPrice)
        
        log("FLOW price updated to $".concat(newPrice.toString()))
    }
}
