import Test

// Test TrixyTypes
access(all) fun testTrixyTypes() {
    let err = Test.deployContract(
        name: "TrixyTypes",
        path: "../contracts/core/TrixyTypes.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    
    log("✅ TrixyTypes deployed successfully")
}

// Test TrixyEvents  
access(all) fun testTrixyEvents() {
    let err = Test.deployContract(
        name: "TrixyEvents",
        path: "../contracts/core/TrixyEvents.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    
    log("✅ TrixyEvents deployed successfully")
}

// Test IStakingProtocol
access(all) fun testIStakingProtocol() {
    let err = Test.deployContract(
        name: "IStakingProtocol",
        path: "../contracts/interfaces/IStakingProtocol.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    
    log("✅ IStakingProtocol deployed successfully")
}

// Test AnkrAdapter
access(all) fun testAnkrAdapter() {
    // Deploy interface first
    Test.deployContract(
        name: "IStakingProtocol",
        path: "../contracts/interfaces/IStakingProtocol.cdc",
        arguments: []
    )
    
    let err = Test.deployContract(
        name: "AnkrAdapter",
        path: "../contracts/adapters/AnkrAdapter.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    
    log("✅ AnkrAdapter deployed successfully")
}

// Test Market
access(all) fun testMarket() {
    // Deploy dependencies
    Test.deployContract(name: "TrixyTypes", path: "../contracts/core/TrixyTypes.cdc", arguments: [])
    Test.deployContract(name: "TrixyEvents", path: "../contracts/core/TrixyEvents.cdc", arguments: [])
    
    let err = Test.deployContract(
        name: "Market",
        path: "../contracts/core/Market.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    
    log("✅ Market deployed successfully")
}

// Test TrixyProtocol
access(all) fun testTrixyProtocol() {
    // Deploy all dependencies
    Test.deployContract(name: "TrixyTypes", path: "../contracts/core/TrixyTypes.cdc", arguments: [])
    Test.deployContract(name: "TrixyEvents", path: "../contracts/core/TrixyEvents.cdc", arguments: [])
    Test.deployContract(name: "Market", path: "../contracts/core/Market.cdc", arguments: [])
    
    let err = Test.deployContract(
        name: "TrixyProtocol",
        path: "../contracts/TrixyProtocol.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    
    log("✅ TrixyProtocol deployed successfully")
}
