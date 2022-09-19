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
    
}

enum AccountError: Error {
    case cannotFetchAccountState
}


