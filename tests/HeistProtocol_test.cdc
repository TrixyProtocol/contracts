import Test
import BlockchainHelpers
import "TrixyTypes"
import "TrixyEvents"
import "Market"
import "TrixyProtocol"

access(all) let admin = Test.getAccount(0x0000000000000007)
access(all) let alice = Test.createAccount()
access(all) let bob = Test.createAccount()

access(all) fun setup() {
    let err = Test.deployContract(
        name: "TrixyTypes",
        path: "../contracts/core/TrixyTypes.cdc",
        arguments: []
    )
    Test.expect(err, Test.beNil())
    
    let err2 = Test.deployContract(
        name: "TrixyEvents",
        path: "../contracts/core/TrixyEvents.cdc",
        arguments: []
    )
    Test.expect(err2, Test.beNil())
    
    let err3 = Test.deployContract(
        name: "Market",
        path: "../contracts/core/Market.cdc",
        arguments: []
    )
    Test.expect(err3, Test.beNil())
    
    let err4 = Test.deployContract(
        name: "TrixyProtocol",
        path: "../contracts/TrixyProtocol.cdc",
        arguments: []
    )
    Test.expect(err4, Test.beNil())
}

access(all) fun testCreateMarket() {
    let code = Test.readFile("../transactions/create_staking_market.cdc")
    
    let futureTime = getCurrentBlock().timestamp + 86400.0
    let tx = Test.Transaction(
        code: code,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [
            "Which protocol will have highest APY?",
            futureTime,
            ["Ankr", "Increment", "Figment"]
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
    
    Test.assertEqual(1, Test.eventsOfType(Type<TrixyEvents.MarketCreated>()).length)
}

access(all) fun testPlaceBet() {
    // Setup FLOW tokens for alice
    setupFlowToken(alice)
    
    let code = Test.readFile("../transactions/place_bet.cdc")
    
    let tx = Test.Transaction(
        code: code,
        authorizers: [alice.address],
        signers: [alice],
        arguments: [
            UInt64(0),
            "Ankr",
            100.0
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
}

access(all) fun testMarketResolution() {
    let code = Test.readFile("../transactions/resolve_market.cdc")
    
    // Fast forward time
    Test.moveTime(by: 86400.0 + 1.0)
    
    let apys: {String: UFix64} = {
        "Ankr": 12.5,
        "Increment": 15.3,
        "Figment": 11.8
    }
    
    let tx = Test.Transaction(
        code: code,
        authorizers: [admin.address],
        signers: [admin],
        arguments: [
            UInt64(0),
            apys
        ]
    )
    
    let result = Test.executeTransaction(tx)
    Test.expect(result, Test.beSucceeded())
}

access(all) fun setupFlowToken(_ account: Test.TestAccount) {
    // Setup FLOW vault for account
    let setupCode = "import FlowToken from 0x0ae53cb6e3f42a79\n"
        .concat("import FungibleToken from 0xee82856bf20e2aa6\n")
        .concat("\n")
        .concat("transaction {\n")
        .concat("    prepare(signer: auth(Storage, Capabilities) &Account) {\n")
        .concat("        if signer.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) == nil {\n")
        .concat("            signer.storage.save(\n")
        .concat("                <-FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()),\n")
        .concat("                to: /storage/flowTokenVault\n")
        .concat("            )\n")
        .concat("            \n")
        .concat("            let cap = signer.capabilities.storage.issue<&FlowToken.Vault>(/storage/flowTokenVault)\n")
        .concat("            signer.capabilities.publish(cap, at: /public/flowTokenReceiver)\n")
        .concat("        }\n")
        .concat("    }\n")
        .concat("}\n")
    
    let tx = Test.Transaction(
        code: setupCode,
        authorizers: [account.address],
        signers: [account],
        arguments: []
    )
    
    Test.executeTransaction(tx)
}
