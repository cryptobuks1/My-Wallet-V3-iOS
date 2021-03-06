//
//  MnemonicAccessMock.swift
//  PlatformKit
//
//  Created by Paulo on 11/08/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit
import RxSwift

class MnemonicAccessMock: MnemonicAccessAPI {
    
    var mnemonic: Maybe<Mnemonic> = .empty()

    var mnemonicForcePrompt: Maybe<Mnemonic> = .empty()

    var mnemonicPromptingIfNeeded: Maybe<Mnemonic> = .empty()

    init() { }
}
