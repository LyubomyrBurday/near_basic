//
//  UIAlert+Extension.swift
//  NearWallet
//
//  Created by Lyubomyr Burday on 19.09.2022.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showAlertWithButtons(title: String, msg: String = "", okHandler:((UIAlertAction)->Void)?) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "UIAlert.Okay".localized(), style: .default, handler: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
          }))
        alertController.addAction(UIAlertAction(title: "UIAlert.Review".localized(),
                                                style: .default,
                                              handler: okHandler))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertWithOneButton(title: String, msg: String = "", okHandler:((UIAlertAction)->Void)?) {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "UIAlert.Okay".localized(),
                                                style: .default,
                                              handler: okHandler))
        self.present(alertController, animated: true, completion: nil)
    }
    
}
