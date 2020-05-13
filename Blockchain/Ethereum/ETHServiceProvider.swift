//
//  ETHServiceProvider.swift
//  Blockchain
//
//  Created by Jack on 26/02/2019.
//  Copyright © 2019 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import RxSwift
import EthereumKit

// TODO: Move this to EthereumKit

protocol ETHDependencies {
    var repository: EthereumWalletAccountRepository { get }
    var assetAccountRepository: EthereumAssetAccountRepository { get }
    var transactionService: EthereumHistoricalTransactionService { get }
    var qrMetadataFactory: EthereumQRMetadataFactory { get }
}

struct ETHServices: ETHDependencies {
    let repository: EthereumWalletAccountRepository
    let assetAccountRepository: EthereumAssetAccountRepository
    let transactionService: EthereumHistoricalTransactionService
    let qrMetadataFactory: EthereumQRMetadataFactory

    init(wallet: Wallet = WalletManager.shared.wallet) {
        self.repository = EthereumWalletAccountRepository(with: wallet.ethereum)
        self.assetAccountRepository = EthereumAssetAccountRepository(
            service: EthereumAssetAccountDetailsService(
                with: wallet.ethereum,
                client: EthereumKit.APIClient()
            )
        )
        self.transactionService = EthereumHistoricalTransactionService(
            with: wallet.ethereum,
            client: EthereumKit.APIClient()
        )
        self.qrMetadataFactory = EthereumQRMetadataFactory()
    }
}

final class ETHServiceProvider {
    
    let services: ETHServices
    
    fileprivate let disposables = CompositeDisposable()
    
    static let shared = ETHServiceProvider.make()
    
    class func make() -> ETHServiceProvider {
        ETHServiceProvider(services: ETHServices())
    }
    
    init(services: ETHServices) {
        self.services = services
    }
    
    var repository: EthereumWalletAccountRepository {
        services.repository
    }
    
    var assetAccountRepository: EthereumAssetAccountRepository {
        services.assetAccountRepository
    }
    
    var transactionService: EthereumHistoricalTransactionService {
        services.transactionService
    }

    var qrMetadataFactory: EthereumQRMetadataFactory {
        services.qrMetadataFactory
    }
}
