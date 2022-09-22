//
//  String+Extension.swift
//  NearWallet
//
//  Created by Lyubomyr Burday on 22.09.2022.
//

import Foundation

extension String {
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        return NSLocalizedString(self, tableName: tableName, value: self, comment: "")
    }
}
