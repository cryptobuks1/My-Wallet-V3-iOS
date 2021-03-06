//
//  UnspentOutputRepository.swift
//  BitcoinKit
//
//  Created by Jack on 08/09/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import DIKit
import PlatformKit
import RxSwift
import ToolKit

protocol UnspentOutputRepositoryAPI {
    var unspentOutputs: Single<UnspentOutputs> { get }
    var fetchUnspentOutputs: Single<UnspentOutputs> { get }
}

final class UnspentOutputRepository: UnspentOutputRepositoryAPI {

    // MARK: - Properties
    
    var unspentOutputs: Single<UnspentOutputs> {
        cachedUnspentOutputs.valueSingle
    }
    
    var fetchUnspentOutputs: Single<UnspentOutputs> {
        cachedUnspentOutputs.fetchValue
    }
    
    // MARK: - Private properties

    private let bridge: BitcoinWalletBridgeAPI
    private let client: APIClientAPI
    private let cachedUnspentOutputs: CachedValue<UnspentOutputs>
    
    // MARK: - Init
    
    init(with bridge: BitcoinWalletBridgeAPI = resolve(),
         client: APIClientAPI = resolve(),
         scheduler: SchedulerType = CachedValueConfiguration.generateScheduler()) {
        self.bridge = bridge
        self.client = client
        
        self.cachedUnspentOutputs = CachedValue<UnspentOutputs>(
            configuration: .periodicAndLogin(10, scheduler: scheduler)
        )
        
        cachedUnspentOutputs.setFetch { [weak self] () -> Single<UnspentOutputs> in
            guard let self = self else {
                return Single.error(ToolKitError.nullReference(Self.self))
            }
            return self.fetchAllUnspentOutputs()
        }
    }
    
    // MARK: - Private methods
    
    private func fetchAllUnspentOutputs() -> Single<UnspentOutputs> {
        bridge.wallets
            .map { wallets -> [String] in
                wallets.map { $0.publicKey }
            }
            .flatMap(weak: self) { (self, addresses) -> Single<UnspentOutputs> in
                self.fetchUnspentOutputs(for: addresses)
            }
    }
    
    private func fetchUnspentOutputs(for addresses: [String]) -> Single<UnspentOutputs> {
        client.unspentOutputs(addresses: addresses)
            .map { UnspentOutputs(networkResponse: $0) }
    }
}

