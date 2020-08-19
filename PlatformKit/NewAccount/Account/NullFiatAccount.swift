//
//  NullFiatAccount.swift
//  PlatformKit
//
//  Created by Paulo on 03/08/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import RxSwift
import ToolKit

public class NullFiatAccount : FiatAccount {

    public let id: String = "NullFiatAccount"

    public var fiatCurrency: String {
        unimplemented()
    }

    public var isDefault: Bool {
        unimplemented()
    }

    public var label: String {
        unimplemented()
    }

    public var balance: Single<MoneyValue> {
        unimplemented()
    }

    public var actions: AvailableActions {
        unimplemented()
    }

    public func fiatBalance(fiatCurrency: FiatCurrency) -> Single<MoneyValue> {
        unimplemented()
    }
}
