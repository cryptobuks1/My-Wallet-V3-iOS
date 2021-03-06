//
//  ActivityServiceContainer.swift
//  Blockchain
//
//  Created by Alex McGregor on 5/5/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit
import RxRelay
import RxSwift

protocol ActivityServiceContaining {
    var asset: Observable<CryptoCurrency> { get }
    var balanceProviding: BalanceProviding { get }
    var exchangeProviding: ExchangeProviding { get }
    var fiatCurrency: FiatCurrencySettingsServiceAPI { get }
    var activity: Observable<ActivityItemEventServiceAPI> { get }
    var selectionServiceAPI: WalletPickerSelectionServiceAPI { get }
}

final class ActivityServiceContainer: ActivityServiceContaining {
    var asset: Observable<CryptoCurrency> {
        selectionServiceAPI
            .selectedData
            .compactMap { $0.currency }
    }
    
    var activityEventsLoadingState: Observable<ActivityItemEventsLoadingState> {
        eventsRelay
            .asObservable()
    }
    
    var activity: Observable<ActivityItemEventServiceAPI> {
        asset.map { currency -> ActivityItemEventServiceAPI in
            self.activityProviding[currency]
        }
    }
    
    let activityProviding: ActivityProviding
    let balanceProviding: BalanceProviding
    let fiatCurrency: FiatCurrencySettingsServiceAPI
    let selectionServiceAPI: WalletPickerSelectionServiceAPI
    let exchangeProviding: ExchangeProviding
    
    private let eventsRelay = BehaviorRelay<ActivityItemEventsLoadingState>(value: .loading)
    private let disposeBag = DisposeBag()
    
    init(fiatCurrency: FiatCurrencySettingsServiceAPI = UserInformationServiceProvider.default.settings,
         balanceProviding: BalanceProviding = DataProvider.default.balance,
         exchangeProviding: ExchangeProviding = DataProvider.default.exchange,
         activityProviding: ActivityProviding = ActivityServiceProvider.default.activity) {
        self.selectionServiceAPI = WalletPickerSelectionService(defaultSelection: .all)
        self.fiatCurrency = fiatCurrency
        self.balanceProviding = balanceProviding
        self.exchangeProviding = exchangeProviding
        self.activityProviding = activityProviding
        
        selectionServiceAPI
            .selectedData
            .do(afterNext: { _ in activityProviding.refresh() })
            .flatMapLatest { selection -> Observable<ActivityItemEventsLoadingState> in
                switch selection {
                case .all:
                    return activityProviding.activityItems
                case .nonCustodial(let currency):
                    let transactional = activityProviding[currency].transactional
                    let swap = activityProviding[currency].swap
                    return Observable.combineLatest(
                            transactional.state,
                            swap.state
                        )
                        .map(weak: self) { (self, states) -> ActivityItemEventsLoadingState in
                            [states.1, states.0].reduce()
                        }
                case .custodial(let currency):
                    return activityProviding[currency].buy.state
                }
            }
            .bindAndCatch(to: eventsRelay)
            .disposed(by: disposeBag)
    }
}
