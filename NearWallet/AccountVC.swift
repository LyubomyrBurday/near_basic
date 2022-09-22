//
//  AccountVC.swift
//  NearWallet
//
//  Created by Lyubomyr Burday on 19.09.2022.
//

import Foundation
import UIKit
import nearclientios

class AccountVC: UIViewController {
    
    let AMOUNT_FOR_TESTING = UInt128(stringLiteral: "10000000000000000000000000")
    
    @IBOutlet weak var lblAccountBalance: UILabel!
    @IBOutlet weak var lblTotalStackedBalance: UILabel!
    @IBOutlet weak var recieverTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var lblCreatedSM: UILabel!
    @IBOutlet weak var lblQuestion: UILabel!
    @IBOutlet weak var answerTextField: UITextField!
    
    @IBOutlet weak var btnCreateSM: UIButton!
    @IBOutlet weak var btnSendMoney: UIButton!
    
    private var walletAccount: WalletAccount?
    private var near: Near?
    private var accountState: AccountState?
    private var account: Account!
    
    
    private var contract: Contract!
    private var contractId: String!
    
    var questions: [String] = ["2 + 2 = ?", "1 + 4 = ?", "10 + 4 = ?", "2 + 2 = ?"]
    
    override func viewDidLoad(){
        super.viewDidLoad()
        setupUI()
        updateAccountData()
    }
    
    func setup(near: Near, wallet: WalletAccount) {
      self.near = near
      walletAccount = wallet
    }
    
    private func setupUI() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "AccountVC.navigationBackButton".localized(), style: UIBarButtonItem.Style.plain, target: self, action: #selector(AccountVC.backWithLogout(sender:)))
        title = "AccountVC.navigationTitle".localized()
        
        btnCreateSM.setTitle("AccountVC.btnCreateSM".localized(), for: .normal)
        btnSendMoney.setTitle("AccountVC.btnSendMoney".localized(), for: .normal)
        
        answerTextField.placeholder = "AccountVC.answerTextField".localized()
        recieverTextField.placeholder = "AccountVC.recieverTextField".localized()
        amountTextField.placeholder = "AccountVC.amountTextField".localized()
    }
    
    func updateAccountData(){
        Task {
            accountState = try await fetchAccountState()
            await setupData(with: accountState!, account: account)
            // Creating a smart contract, this block is used to demonstrate the creation of a smart contract and further interaction with it
            try await contractSetup()
        }
    }
    
    private func setupData(with accountState: AccountState, account: Account) async {
        lblAccountBalance.text = try! await "\("AccountVC.lblAccountBalance".localized()) \(account.getAccountBalance().available.toNearAmount(fracDigits: 5)) Ⓝ"
        lblTotalStackedBalance.text = try! await "\("AccountVC.lblTotalStackedBalance".localized()) \(account.getAccountBalance().staked)"
        lblQuestion.text = questions[Int.random(in: 0..<4)]
    }
    
    // We receive up-to-date information about the user's profile
    private func fetchAccountState() async throws -> AccountState {
        do {
            account = try await near!.account(accountId: walletAccount!.getAccountId())
            return try await account.state()
        } catch {
            throw AccountError.cannotFetchAccountState
        }
    }
    
    // We create a smart contract with the PubliKey connection, which can be regenerated if necessary.
    private func contractSetup() async throws {
        contractId = generateUniqueString(prefix: "test_contract")
        
        // An example of generating a new PublicKey
        // let newPublicKey = try await near!.connection.signer.createKey(accountId: account.accountId, networkId: account.connection.networkId, curve: .ED25519)
        
        guard let myKey = try await near!.connection.signer.getPublicKey(accountId: account.accountId, networkId: account.connection.networkId) else {
            print("Втрачений ключ \(account.accountId) в \(account.connection.networkId)")
          return
        }

        try await account.createAndDeployContract(contractId: contractId, publicKey: myKey, data: Wasm().data.bytes, amount: AMOUNT_FOR_TESTING)
        let options = ContractOptions(viewMethods: [.hello, .getValue, .getAllKeys, .returnHiWithLogs], changeMethods: [.setValue, .generateLogs, .triggerAssert, .testSetRemove], sender: nil)
        contract = Contract(account: account, contractId: contractId, options: options)
        try await makeFunctionCallViaAccount()
    }
    
    // Calling the account.viewFunction() and account.functionCall() methods
    private func makeFunctionCallViaAccount() async throws {
        let result: String = try await account.viewFunction(contractId: contractId, methodName: .hello, args: ["name": "trex"])
        let result2 = try await account.functionCall(contractId: contractId, methodName: .setValue, args: ["value": generateUniqueString(prefix: "iPhone 14")], amount: 1)
        let viewResult: String = try await account.viewFunction(contractId: contractId, methodName: .getValue, args: [:])
        print("makeFunctionCallViaAccount: account.viewFunction - \(result)")
        print("makeFunctionCallViaAccount: account.functionCall - \(result2)")
        print("makeFunctionCallViaAccount: account.viewFunction - \(viewResult)")
        
        try await testMakeFunctionCallsViaAccountWithGas()
    }
    
    // Calling the contract.view(), contract.change() methods and the additional parameter Gas
    private func testMakeFunctionCallsViaAccountWithGas() async throws {
        let result: String = try await contract.view(methodName: .hello, args: ["name": "world"])
        let result2 = try await contract.change(methodName: .setValue, args: ["value": generateUniqueString(prefix: "iPhone 14"), "amount": 5] , gas: 1000000 * 1000000)
        let viewResult: String = try await contract.view(methodName: .getValue)
        print("testMakeFunctionCallsViaAccountWithGas: account.viewFunction - \(result)")
        print("testMakeFunctionCallsViaAccountWithGas: account.functionCall - \(String(describing: result2))")
        print("testMakeFunctionCallsViaAccountWithGas: account.viewFunction - \(viewResult)")
    }
    
    @IBAction func touchUpMakeContractRequests(_ sender: UIButton) {
        Task {
            do {
                try await contract.change(methodName: .setValue, args: ["question": lblQuestion.text! ,"value": answerTextField.text!], amount: convertToYoctoNears(nears: 0.1))
                let viewResult: String = try await contract.view(methodName: .getValue)
                lblCreatedSM.text = "\("AccountVC.lblCreatedSM".localized())\(String(describing: contractId))\("AccountVC.lblCreatedSMadditional".localized())\(viewResult)"
                updateAccountData()
            } catch {
                await MainActor.run {
                    showAlertWithOneButton(title: "AccountVC.alertErrorButtonTitle".localized(), msg: "\(error)", okHandler: { (alert) in
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            }
        }
    }
    
    // Sending funds using the account.sendMoney() method
    @IBAction func touchUpSendMoney(_ sender: UIButton) {
        Task {
            do {
                let result = try await account.sendMoney(receiverId: recieverTextField.text!, amount: convertToYoctoNears(nears: Double(amountTextField.text!)!))
                showAlertWithButtons(title: "AccountVC.alertSuccessTitle".localized(), msg: "\(amountTextField.text!) \("AccountVC.alertSuccessDescription".localized())", okHandler: { (alert) in
                    if let url = URL(string: "https://explorer.testnet.near.org/transactions/\(result.transaction.hash)") {
                        UIApplication.shared.open(url)
                    }
                    self.dismiss(animated: true, completion: nil)
                })
                updateAccountData()
            } catch {
                await MainActor.run {
                    showAlertWithOneButton(title: "AccountVC.alertErrorTitle".localized(), msg: "\(error)", okHandler: { (alert) in
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            }
        }
    }
    
    @objc private func backWithLogout(sender: UIBarButtonItem) {
      Task {
          await walletAccount?.signOut()
          navigationController?.popViewController(animated: true)
      }
    }
    
    func generateUniqueString(prefix: String) -> String {
      var result = prefix + "-\(Int(Date().timeIntervalSince1970 * 1000))" + "-\(Int.random(in: 0..<1000000))"
      let add_symbols = max(64 - result.count, 1)
      for _ in 0..<add_symbols {
        result += "0"
      }
      return result
    }
    
    func convertToYoctoNears(nears: Double) -> UInt2X<UInt64> {
        return UInt2X<UInt64>(nears * 1000000000000000000000000)
    }
    
}

enum AccountError: Error {
    case cannotFetchAccountState
}

internal class Wasm {
  lazy var data: Data = {
    let testBundle = Bundle(for: type(of: self))
    guard let fileURL = testBundle.url(forResource: "main", withExtension: "wasm") else { fatalError() }
    return try! Data(contentsOf: fileURL)
  }()
}
