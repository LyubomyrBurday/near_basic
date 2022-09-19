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
    
    @IBOutlet weak var lblAccountBalance: UILabel!
    @IBOutlet weak var lblTotalStackedBalance: UILabel!
    @IBOutlet weak var recieverTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    
    private var walletAccount: WalletAccount?
    private var near: Near?
    private var accountState: AccountState?
    private var account: Account!
    private var contract: Contract!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Вихід", style: UIBarButtonItem.Style.plain, target: self, action: #selector(AccountVC.backWithLogout(sender:)))
        Task {
            accountState = try await fetchAccountState()
            await setupData(with: accountState!, account: account)
        }
    }
    
    @objc private func backWithLogout(sender: UIBarButtonItem) {
      Task {
          await walletAccount?.signOut()
          navigationController?.popViewController(animated: true)
      }
    }
    
    func setup(near: Near, wallet: WalletAccount) {
      self.near = near
      walletAccount = wallet
    }
    
    private func setupData(with accountState: AccountState, account: Account) async {
        lblAccountBalance.text = try! await "Баланс профілю: \(account.getAccountBalance().available.toNearAmount(fracDigits: 5)) Ⓝ"
        lblTotalStackedBalance.text = try! await "Стейкінг баланс: \(account.getAccountBalance().staked)"
        
    }
    
    private func fetchAccountState() async throws -> AccountState {
        do {
            account = try await near!.account(accountId: walletAccount!.getAccountId())
            let state = try await account.state()
            return state
        } catch {
            throw AccountError.cannotFetchAccountState
        }
    }
    
    @IBAction func touchUpMakeContractRequests(_ sender: UIButton) {
        Task {
            do {
                // Генеруємо унікальний ідентифікатор СК
                let contractId = generateUniqueString(prefix: "test_contract")
                
                // Створюємо ключ для підпису
                let newPublicKey = try await near!.connection.signer.createKey(accountId: contractId, networkId: account.connection.networkId, curve: .ED25519)
                
                // Створюємо та деплоїмо СК, amount - вказується в yoctoNear
                let createdContract = try await account.createAndDeployContract(contractId: contractId, publicKey: newPublicKey, data: Wasm().data.bytes, amount: UInt128(stringLiteral: "1000000000000000000000000"))
                let options = ContractOptions(viewMethods: [.getValue, .getLastResult],
                                              changeMethods: [.setValue,  .callPromise],
                                              sender: nil)
                contract = Contract(account: account, contractId: contractId, options: options)
                
                let result: String = try await contract.view(methodName: .hello, args: ["name": "trex"])
                print("contract.view methodName .hello - \(result)")
                let result2: String = try await contract.change(methodName: .setValue, args: ["value": generateUniqueString(prefix: "uniqueString")], amount: UInt128(stringLiteral: "1000000000000000000000000")) as! String
                print("contract.view methodName .setValue - \(result2)")
                let testSetCallValue: String = try await contract.view(methodName: .getValue)
                print("contract.view methodName .getValue - \(testSetCallValue)")
            } catch {
                await MainActor.run {
                    showAlertWithOneButton(title: "Помилка", msg: "\(error)", okHandler: { (alert) in
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            }
        }
        // Потрібно оновити UI
    }
    
    
    @IBAction func touchUpSendMoney(_ sender: UIButton) {
        Task {
            do {
                let result = try await account.sendMoney(receiverId: recieverTextField.text!, amount: UInt128(stringLiteral: amountTextField.text!))
                showAlertWithButtons(title: "Успішно", msg: "\(amountTextField.text!) NEARs успішно відправлено. Бажаєте переглянути транзакцію?", okHandler: { (alert) in
                    if let url = URL(string: "https://explorer.testnet.near.org/transactions/\(result.transaction.hash)") {
                        UIApplication.shared.open(url)
                    }
                    self.dismiss(animated: true, completion: nil)
                })
            } catch {
                await MainActor.run {
                    showAlertWithOneButton(title: "Помилка", msg: "\(error)", okHandler: { (alert) in
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            }
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
