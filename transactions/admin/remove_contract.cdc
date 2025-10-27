transaction(contractName: String) {
    prepare(signer: auth(RemoveContract) &Account) {
        signer.contracts.remove(name: contractName)
    }
}
