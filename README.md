# Про проект
Даний проект розроблений для демонстрації основних функціх та базового функціоналу [nearclientios](https://github.com/near/near-api-swift).
Початок роботи з бібліотекою починається з створення config об'єкту та ініціалізації об'єктів типу Near та WalletAcount.
Користувач використовує наявний аккаунт або створює новий за допомогою WebView, який реалізований в [nearclientios](https://github.com/near/near-api-swift) та отримує вище описані об'єкти з PublicKey.
Володіючи PublicKey ми можемо використовувати та підписувати методи без необхідності додаткового підтвердження від користувача.

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
Приклад створення смарт контракту для подальшого використання
```swift
private func contractSetup() async throws {
        let contractId = generateUniqueString(prefix: "test_contract")
        let myKey = try await near!.connection.signer.getPublicKey(accountId: account.accountId, networkId: account.connection.networkId)

        try await account.createAndDeployContract(contractId: contractId, publicKey: myKey, data: Wasm().data.bytes, amount: AMOUNT_FOR_TESTING)
        let options = ContractOptions(viewMethods: [.hello, .getValue, .getAllKeys, .returnHiWithLogs], changeMethods: [.setValue, .generateLogs, .triggerAssert, .testSetRemove], sender: nil)
        contract = Contract(account: account, contractId: contractId, options: options)
    }
```
Приклад використання методів account.viewFunction() та account.functionCall() для запису в смарт контракт
```swift
 private func makeFunctionCallViaAccount() async throws {
        try await account.viewFunction(contractId: contractId, methodName: .hello, args: ["name": "trex"])
        try await account.functionCall(contractId: contractId, methodName: .setValue, args: ["value": generateUniqueString(prefix: "iPhone 14")], amount: 1)
        let viewResult: String = try await account.viewFunction(contractId: contractId, methodName: .getValue, args: [:])
    }
```
Приклад використання методу надсилання коштів іншому користувачу
```swift
try await contract.change(methodName: .setValue, args: ["question": "test.testnet" ,"value": answerTextField.text!], amount: convertToYoctoNears(nears: 1))
```
Інші базові методи можна переглянути у контроллерів AccountVC.swift.

# Вимоги
[nearclientios](https://github.com/near/near-api-swift) використовує iOS 13+ та Swift async/await

# Самостійне встановлення
## CocoaPods
[nearclientios](https://github.com/near/near-api-swift) можливо встановити за допомогою CocoaPods. Щоб встановити необхідно додати наступний рядок в Podfile.
```swift
pod 'nearclientios'
```
## Swift Package Manager
[nearclientios](https://github.com/near/near-api-swift) можливо встановити за допомогою Swift Package Manager додавши залежність в Package.swift.
```swift
dependencies: [
  .package(url: "https://github.com/near/near-api-swift", .upToNextMajor(from: "1.0.29"))
]
```
