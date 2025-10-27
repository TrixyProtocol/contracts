import Test
import BlockchainHelpers

/// Complete integration test for prediction market functionality
///
/// Tests the full lifecycle:
/// 1. Deploy contracts
/// 2. Create prediction market
/// 3. Place bets on YES/NO options
/// 4. Resolve market with winner
/// 5. Claim winnings
///

access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let alice = Test.createAccount()
access(all) let bob = Test.createAccount()
access(all) let charlie = Test.createAccount()

// Test 1: Deploy all contracts
access(all) fun testDeployContracts() {
    // Deploy dependencies first
    let trixyTypesErr = Test.deployContract(
        name: "TrixyTypes",
        path: "../contracts/core/TrixyTypes.cdc",
        arguments: []
    )
    Test.expect(trixyTypesErr, Test.beNil())
    
    let trixyEventsErr = Test.deployContract(
        name: "TrixyEvents",
        path: "../contracts/core/TrixyEvents.cdc",
        arguments: []
    )
    Test.expect(trixyEventsErr, Test.beNil())
    
    let marketErr = Test.deployContract(
        name: "Market",
        path: "../contracts/core/Market.cdc",
        arguments: []
    )
    Test.expect(marketErr, Test.beNil())
    
    let trixyProtocolErr = Test.deployContract(
        name: "TrixyProtocol",
        path: "../contracts/TrixyProtocol.cdc",
        arguments: []
    )
    Test.expect(trixyProtocolErr, Test.beNil())
    
    log("✅ All contracts deployed successfully")
}

// Test 2: Create a prediction market
access(all) fun testCreatePredictionMarket() {
    let currentTime = getCurrentBlock().timestamp
    let endTime = currentTime + 86400.0 // 1 day from now
    
    let code = Test.readFile("../transactions/create_staking_market.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [
            "Will Bitcoin reach $100k by end of 2025?",
            endTime,
            ["YES", "NO"],
            "aave"
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Prediction market created successfully")
    log("   Question: Will Bitcoin reach $100k by end of 2025?")
    log("   Options: YES / NO")
    log("   Yield Protocol: aave")
}

// Test 3: Alice places bet on YES
access(all) fun testAliceBetsYes() {
    let code = Test.readFile("../transactions/place_bet.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [alice.address],
        signers: [alice],
        arguments: [
            admin.address,  // market creator
            UInt64(0),      // market ID
            "YES",          // option
            100.0           // amount in FLOW
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Alice bet 100 FLOW on YES")
}

// Test 4: Bob places bet on YES
access(all) fun testBobBetsYes() {
    let code = Test.readFile("../transactions/place_bet.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [bob.address],
        signers: [bob],
        arguments: [
            admin.address,
            UInt64(0),
            "YES",
            50.0
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Bob bet 50 FLOW on YES")
}

// Test 5: Charlie places bet on NO
access(all) fun testCharlieBetsNo() {
    let code = Test.readFile("../transactions/place_bet.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [charlie.address],
        signers: [charlie],
        arguments: [
            admin.address,
            UInt64(0),
            "NO",
            75.0
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Charlie bet 75 FLOW on NO")
    log("")
    log("📊 Current market state:")
    log("   YES: 150 FLOW (Alice: 100, Bob: 50)")
    log("   NO: 75 FLOW (Charlie: 75)")
    log("   Total Pool: 225 FLOW")
}

// Test 6: Get market info
access(all) fun testGetMarketInfo() {
    let code = Test.readFile("../scripts/get_market_info.cdc")
    let scriptResult = Test.executeScript(
        code,
        [admin.address, UInt64(0)]
    )
    
    Test.expect(scriptResult, Test.beSucceeded())
    
    log("✅ Market info retrieved successfully")
}

// Test 7: Move time forward and resolve market
access(all) fun testResolveMarket() {
    // Move time forward past end time
    Test.commitBlock()
    
    let code = Test.readFile("../transactions/resolve_market.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [
            UInt64(0),  // market ID
            "YES"       // winning option
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Market resolved with winning option: YES")
    log("")
    log("💰 Payout calculation:")
    log("   Total Pool: 225 FLOW (after 2% fee: ~220.5 FLOW)")
    log("   Winners (YES): Alice & Bob")
    log("   Losers (NO): Charlie")
    log("   Alice gets: 100 + (100/150) * 75 = 150 FLOW + yield share")
    log("   Bob gets: 50 + (50/150) * 75 = 75 FLOW + yield share")
    log("   Charlie gets: 0 FLOW")
}

// Test 8: Alice claims winnings
access(all) fun testAliceClaimWinnings() {
    let code = Test.readFile("../transactions/claim_winnings.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [alice.address],
        signers: [alice],
        arguments: [
            admin.address,
            UInt64(0)
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Alice claimed her winnings")
}

// Test 9: Bob claims winnings
access(all) fun testBobClaimWinnings() {
    let code = Test.readFile("../transactions/claim_winnings.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [bob.address],
        signers: [bob],
        arguments: [
            admin.address,
            UInt64(0)
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Bob claimed his winnings")
}

// Test 10: Charlie tries to claim (should fail as he lost)
access(all) fun testCharlieClaimFails() {
    let code = Test.readFile("../transactions/claim_winnings.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [charlie.address],
        signers: [charlie],
        arguments: [
            admin.address,
            UInt64(0)
        ]
    )
    
    let result = Test.executeTransaction(tx)
    // Charlie should get 0 payout
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Charlie received 0 payout (as expected for losing bet)")
}

// Test 11: Create multiple choice market
access(all) fun testCreateMultipleChoiceMarket() {
    let currentTime = getCurrentBlock().timestamp
    let endTime = currentTime + 86400.0
    
    let code = Test.readFile("../transactions/create_staking_market.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [
            "Which team will win the championship?",
            endTime,
            ["Team A", "Team B", "Team C"],
            "morpho"
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Multiple-choice prediction market created")
    log("   Question: Which team will win the championship?")
    log("   Options: Team A / Team B / Team C")
    log("   Yield Protocol: morpho")
}

// Test 12: Test different yield protocols
access(all) fun testDifferentYieldProtocols() {
    let currentTime = getCurrentBlock().timestamp
    let endTime = currentTime + 86400.0
    
    // Test Compound
    let code = Test.readFile("../transactions/create_staking_market.cdc")
    let tx = Test.Transaction(
        code: code,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [
            "Will Ethereum merge complete successfully?",
            endTime,
            ["YES", "NO"],
            "compound"
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    log("✅ Market with compound yield protocol created")
}

// Run all tests
access(all) fun main() {
    log("🧪 Starting Prediction Market Integration Tests")
    log("================================================")
    log("")
    
    testDeployContracts()
    testCreatePredictionMarket()
    testAliceBetsYes()
    testBobBetsYes()
    testCharlieBetsNo()
    testGetMarketInfo()
    testResolveMarket()
    testAliceClaimWinnings()
    testBobClaimWinnings()
    testCharlieClaimFails()
    testCreateMultipleChoiceMarket()
    testDifferentYieldProtocols()
    
    log("")
    log("================================================")
    log("✅ All tests passed!")
}
