# About the project
This project is designed to demonstrate the main functions and basic functionality of [nearclientios](https://github.com/near/near-api-swift).
Getting started with the library begins with creating a config object and initializing Near and WalletAcount objects.
The user uses an existing account or creates a new one using WebView, which is implemented in [nearclientios](https://github.com/near/near-api-swift) and receives the objects described above from PublicKey.
Having the PublicKey, we can use and sign methods without the need for additional confirmation from the user.

Read this in other languages: [Ukrainian](https://github.com/LyubomyrBurday/near_basic/blob/main/README.md)

```swift
private var walletAccount: WalletAccount?
private var near: Near?
  
private func setupWallet() async -> WalletAccount {
      let keyStore = SecureEnclaveKeyStore(keychain: .init(service: "example.keystore"))
      keyStore.context = LAContext()
      let config = NearConfig(
        networkId: API.NODE_URL,
        nodeUrl: URL(string: API.NETWORK_ID)!,
        masterAccount: nil,
        keyPath: nil,
        helperUrl: nil,
        initialBalance: nil,
        providerType: .jsonRPC(URL(string: API.JSON_RPC)!),
        signerType: .inMemory(keyStore),
        keyStore: keyStore,
        contractName: nil,
        walletUrl: API.WALLET_URL
      )
      near = Near(config: config)
      return try! WalletAccount(near: near!, authService: DefaultAuthService.shared)
    }
```
An example of creating a smart contract for further use
```swift
private func contractSetup() async throws {
        let contractId = generateUniqueString(prefix: "test_contract")
        let myKey = try await near!.connection.signer.getPublicKey(accountId: account.accountId, networkId: account.connection.networkId)

        try await account.createAndDeployContract(contractId: contractId, publicKey: myKey, data: Wasm().data.bytes, amount: AMOUNT_FOR_TESTING)
        let options = ContractOptions(viewMethods: [.hello, .getValue, .getAllKeys, .returnHiWithLogs], changeMethods: [.setValue, .generateLogs, .triggerAssert, .testSetRemove], sender: nil)
        contract = Contract(account: account, contractId: contractId, options: options)
    }
```
An example of using the account.viewFunction() and account.functionCall() methods to write to a smart contract
```swift
 private func makeFunctionCallViaAccount() async throws {
        try await account.viewFunction(contractId: contractId, methodName: .hello, args: ["name": "trex"])
        try await account.functionCall(contractId: contractId, methodName: .setValue, args: ["value": generateUniqueString(prefix: "iPhone 14")], amount: 1)
        let viewResult: String = try await account.viewFunction(contractId: contractId, methodName: .getValue, args: [:])
    }
```
An example of using the method of sending funds to another user
```swift
try await contract.change(methodName: .setValue, args: ["question": "test.testnet" ,"value": answerTextField.text!], amount: convertToYoctoNears(nears: 1))
```
Other base methods can be viewed in the controller AccountVC.swift.

# Requirements
[nearclientios](https://github.com/near/near-api-swift) use iOS 13+ та Swift async/await

# Self-installation
## CocoaPods
[nearclientios](https://github.com/near/near-api-swift) can be installed using CocoaPods. To install, you need to add the following line to the Podfile.
```swift
pod 'nearclientios'
```
## Swift Package Manager
[nearclientios](https://github.com/near/near-api-swift) it is possible to install using the Swift Package Manager by adding a dependency to Package.swift.
```swift
dependencies: [
  .package(url: "https://github.com/near/near-api-swift", .upToNextMajor(from: "1.0.29"))
]
```
