//
//  SessionTokenRepositoryAPI.swift
//  Blockchain
//
//  Created by Daniel Huri on 14/11/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

public protocol SessionTokenRepositoryAPI: class {
    var hasSessionToken: Bool { get }
    var sessionToken: String! { get set }
}

public extension SessionTokenRepositoryAPI {
    var hasSessionToken: Bool {
        return sessionToken != nil
    }
}