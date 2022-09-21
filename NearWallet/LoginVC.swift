//
//  ViewController.swift
//  NearWallet
//
//  Created by Lyubomyr Burday on 18.09.2022.
//

import UIKit
import nearclientios
import LocalAuthentication

class LoginVC: UIViewController, WalletSignInDelegate {
    
    private var walletAccount: WalletAccount?
    private var near: Near?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      Task {
        walletAccount = await setupWallet()
        await setupUI(with: walletAccount!)
      }
    }
    
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

    private func setupUI(with wallet: WalletAccount) async {
      if await wallet.isSignedIn() {
        await MainActor.run {
            showAccountState(with: wallet)
        }
      } else {
        // Можна ховати Loader
      }
    }
    
    @IBAction func touchUpAuthButton(_ sender: UIButton) {
        Task {
            DefaultAuthService.shared.walletSignIn = self
            try! await walletAccount!.requestSignIn(contractId: nil, title: GLOBAL.appName, presentingViewController: self)
        }
    }
    
    private func showAccountState(with wallet: WalletAccount) {
      guard let accountVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AccountVC") as? AccountVC else {
        return
      }
      accountVC.setup(near: near!, wallet: wallet)
      navigationController?.pushViewController(accountVC, animated: true)
    }
    
    func completeSignIn(url: URL) async {
        do {
          try await walletAccount?.completeSignIn(url: url)
        } catch {
          await MainActor.run {
              showAlertWithOneButton(title: "Помилка", msg: "\(error)", okHandler: { (alert) in
                  self.dismiss(animated: true, completion: nil)
              })
          }
        }
        await setupUI(with: walletAccount!)
      }
    
}

