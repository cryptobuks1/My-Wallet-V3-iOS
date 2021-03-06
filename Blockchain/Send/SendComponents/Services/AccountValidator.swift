//
//  AccountValidator.swift
//  Blockchain
//
//  Created by Daniel Huri on 15/08/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import EthereumKit
import PlatformKit

final class AccountValidator {
    func validate(address: String, as asset: CryptoCurrency) -> Bool {
        switch asset {
        case .ethereum:
            return EthereumAccountAddress(rawValue: address) != nil
        default:
            fatalError("\(#function) does not support \(asset) yet")
        }
    }
}
