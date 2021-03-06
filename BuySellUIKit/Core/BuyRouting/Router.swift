//
//  SimpleBuyRouter.swift
//  Blockchain
//
//  Created by Daniel Huri on 21/01/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import BuySellKit
import Localization
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit

public protocol RouterAPI: class {
    func setup(startImmediately: Bool)
    func start()
    func next(to state: StateService.State)
    func previous(from state: StateService.State)
    func showCryptoSelectionScreen()
}

/// This object is used as a router for Simple-Buy flow
public final class Router: RouterAPI {
    
    // MARK: - Types
    
    private typealias AnalyticsEvent = AnalyticsEvents.SimpleBuy
    
    // MARK: - Private Properties
    
    private let recordingProvider: RecordingProviderAPI
    private let stateService: StateServiceAPI
    private let kycRouter: KYCRouterAPI
    private let kycServiceProvider: KYCServiceProviderAPI
    private let serviceProvider: ServiceProviderAPI
    private let cardServiceProvider: CardServiceProviderAPI
    private let userInformationProvider: UserInformationServiceProviding
    private let cryptoSelectionService: SelectionServiceAPI & CryptoCurrencyServiceAPI
    private let exchangeProvider: ExchangeProviding
    private let navigationRouter: NavigationRouterAPI
    
    private var cardRouter: CardRouter!
    
    /// A kyc subscription dispose bag
    private var kycDisposeBag = DisposeBag()
        
    /// A general dispose bag
    private let disposeBag = DisposeBag()
    
    private let builder: Buildable
    
    // MARK: - Setup
    
    public init(navigationRouter: NavigationRouterAPI,
                serviceProvider: ServiceProviderAPI,
                cardServiceProvider: CardServiceProviderAPI,
                userInformationProvider: UserInformationServiceProviding,
                builder: Buildable,
                kycServiceProvider: KYCServiceProviderAPI,
                recordingProvider: RecordingProviderAPI,
                kycRouter: KYCRouterAPI,
                exchangeProvider: ExchangeProviding) {
        self.navigationRouter = navigationRouter
        self.recordingProvider = recordingProvider
        self.serviceProvider = serviceProvider
        self.userInformationProvider = userInformationProvider
        self.cardServiceProvider = cardServiceProvider
        self.stateService = builder.stateService
        self.kycServiceProvider = kycServiceProvider
        self.exchangeProvider = exchangeProvider
        self.kycRouter = kycRouter
                
        self.builder = builder
        
        let cryptoSelectionService = CryptoCurrencySelectionService(
            service: serviceProvider.supportedPairsInteractor,
            defaultSelectedData: CryptoCurrency.bitcoin
        )
        
        self.cryptoSelectionService = cryptoSelectionService
    }
    
    public func showCryptoSelectionScreen() {
        typealias LocalizedString = LocalizationConstants.SimpleBuy.CryptoSelectionScreen
        let interactor = SelectionScreenInteractor(service: cryptoSelectionService)
        let presenter = SelectionScreenPresenter(
            title: LocalizedString.title,
            searchBarPlaceholder: LocalizedString.searchBarPlaceholder,
            interactor: interactor
        )
        let viewController = SelectionScreenViewController(presenter: presenter)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationRouter.navigationControllerAPI?.present(navigationController, animated: true, completion: nil)
    }
            
    /// Should be called once
    public func setup(startImmediately: Bool) {
        stateService.action
            .bindAndCatch(weak: self) { (self, action) in
                switch action {
                case .previous(let state):
                    self.previous(from: state)
                case .next(let state):
                    self.next(to: state)
                case .dismiss:
                    self.navigationRouter.navigationControllerAPI?.dismiss(animated: true, completion: nil)
                }
            }
            .disposed(by: disposeBag)
        if startImmediately {
            stateService.nextRelay.accept(())
        }
    }
    
    /// Should be called once
    public func start() {
        setup(startImmediately: true)
    }
    
    public func next(to state: StateService.State) {
        switch state {
        case .intro:
            showIntroScreen()
        case .changeFiat:
            let settingsService = userInformationProvider.settings
            settingsService
                .fiatCurrency
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] currency in
                    self?.showFiatCurrencyChangeScreen(selectedCurrency: currency)
                })
                .disposed(by: disposeBag)
        case .selectFiat:
            let settingsService = userInformationProvider.settings
            settingsService
                .fiatCurrency
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] currency in
                    self?.showFiatCurrencySelectionScreen(selectedCurrency: currency)
                })
                .disposed(by: disposeBag)
        case .unsupportedFiat(let currency):
            showInelligibleCurrency(with: currency)
        case .buy:
            showBuyCryptoScreen()
        case .checkout(let data):
            showCheckoutScreen(with: data)
        case .pendingOrderDetails(let data):
            showCheckoutScreen(with: data)
        case .authorizeCard(let data):
            showCardAuthorization(with: data)
        case .pendingOrderCompleted(amount: let amount, orderId: let orderId):
            showPendingOrderCompletionScreen(for: orderId, cryptoValue: amount)
        case .paymentMethods:
            showPaymentMethodsScreen()
        case .bankTransferDetails(let data):
            showBankTransferDetailScreen(with: data)
        case .fundsTransferDetails(let currency, isOriginPaymentMethods: let isOriginPaymentMethods, let isOriginDeposit):
            showFundsTransferDetailsScreen(with: currency, shouldDismissModal: isOriginPaymentMethods, isOriginDeposit: isOriginDeposit)
        case .transferCancellation(let data):
            showTransferCancellation(with: data)
        case .kyc:
            showKYC(afterDismissal: true)
        case .kycBeforeCheckout:
            showKYC(afterDismissal: false)
        case .pendingKycApproval, .ineligible:
            /// Show pending KYC approval for `ineligible` state as well, since the expected poll result would be
            /// ineligible anyway
            showPendingKycApprovalScreen()
        case .addCard(let data):
            startCardAdditionFlow(with: data)
        case .inactive:
            navigationRouter.navigationControllerAPI?.dismiss(animated: true, completion: nil)
        }
    }
    
    public func previous(from state: StateService.State) {
        switch state {
        // Some independent flows which dismiss themselves.
        // Therefore, do nothing.
        case .kyc, .selectFiat, .changeFiat, .unsupportedFiat, .addCard:
            break
        case .paymentMethods, .bankTransferDetails, .fundsTransferDetails:
            navigationRouter.topMostViewControllerProvider.topMostViewController?.dismiss(animated: true, completion: nil)
        default:
            navigationRouter.dismiss()
        }
    }
    
    private func startCardAdditionFlow(with checkoutData: CheckoutData) {
        let interactor = stateService.cardRoutingInteractor(
            with: checkoutData,
            cardServiceProvider: cardServiceProvider
        )
        let builder = CardComponentBuilder(
            routingInteractor: interactor,
            recordingProvider: recordingProvider
        )
        cardRouter = CardRouter(
            interactor: interactor,
            builder: builder,
            routingType: .modal
        )
        
        /// TODO: This is a temporary patch of the card router intialization, and should not be called directly.
        /// The reason that it is called directly now is that the `Self` is not a RIBs based. Once BuySell's router
        /// moves into RIBs we will delete that like
        cardRouter.load()
    }
    
    private func showFiatCurrencyChangeScreen(selectedCurrency: FiatCurrency) {
        let selectionService = FiatCurrencySelectionService(
            defaultSelectedData: selectedCurrency,
            provider: FiatCurrencySelectionProvider(supportedCurrencies: serviceProvider.supportedCurrencies)
        )
        let interactor = SelectionScreenInteractor(service: selectionService)
        let presenter = SelectionScreenPresenter(
            title: LocalizationConstants.localCurrency,
            description: LocalizationConstants.localCurrencyDescription,
            searchBarPlaceholder: LocalizationConstants.Settings.SelectCurrency.searchBarPlaceholder,
            interactor: interactor
        )
        let viewController = SelectionScreenViewController(presenter: presenter)
        if #available(iOS 13.0, *) {
            viewController.isModalInPresentation = true
        }
        
        recordingProvider.analytics.record(event: AnalyticsEvent.sbCurrencySelectScreen)
        
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationRouter.navigationControllerAPI?.present(navigationController, animated: true, completion: nil)
        
        interactor.selectedIdOnDismissal
            .map { FiatCurrency(code: $0)! }
            .flatMap(weak: self, { (self, currency) -> Single<FiatCurrency> in
                // TICKET: IOS-3144
                self.serviceProvider.settings
                    .update(
                        currency: currency,
                        context: .simpleBuy
                    )
                    .andThen(Single.just(currency))
            })
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] currency in
                    guard let self = self else { return }
                    /// TODO: Remove this and `fiatCurrencySelected` once `ReceiveBTC` and
                    /// `SendBTC` are replaced with Swift implementations.
                    NotificationCenter.default.post(name: .fiatCurrencySelected, object: nil)
                    self.recordingProvider.analytics.record(event: AnalyticsEvent.sbCurrencySelected(currencyCode: currency.code))
                    
                    self.stateService.previousRelay.accept(())
                })
            .disposed(by: disposeBag)
    }
    
    private func showFiatCurrencySelectionScreen(selectedCurrency: FiatCurrency) {
        let selectionService = FiatCurrencySelectionService(defaultSelectedData: selectedCurrency)
        let interactor = SelectionScreenInteractor(service: selectionService)
        let presenter = SelectionScreenPresenter(
            title: LocalizationConstants.localCurrency,
            description: LocalizationConstants.localCurrencyDescription,
            shouldPreselect: false,
            searchBarPlaceholder: LocalizationConstants.Settings.SelectCurrency.searchBarPlaceholder,
            interactor: interactor
        )
        let viewController = SelectionScreenViewController(presenter: presenter)
        if #available(iOS 13.0, *) {
            viewController.isModalInPresentation = true
        }
        
        if navigationRouter.navigationControllerAPI == nil {
            navigationRouter.present(viewController: viewController)
        } else {
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationRouter.navigationControllerAPI?.present(navigationController, animated: true, completion: nil)
        }
        
        interactor.dismiss
            .bind { [weak self] in
                self?.stateService.previousRelay.accept(())
            }
            .disposed(by: disposeBag)
        
        interactor.selectedIdOnDismissal
            .map { FiatCurrency(code: $0)! }
            .flatMap(weak: self, { (self, currency) -> Single<(FiatCurrency, Bool)> in

                let isCurrencySupported = self.serviceProvider.supportedPairsInteractor
                    .fetch()
                    .map { !$0.pairs.isEmpty }
                    .take(1)
                    .asSingle()

                // TICKET: IOS-3144
                return self.serviceProvider.settings
                    .update(
                        currency: currency,
                        context: .simpleBuy
                    )
                    .andThen(Single.zip(
                        Single.just(currency),
                        isCurrencySupported
                    ))
            })
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] value in
                    guard let self = self else { return }
                    /// TODO: Remove this and `fiatCurrencySelected` once `ReceiveBTC` and
                    /// `SendBTC` are replaced with Swift implementations.
                    NotificationCenter.default.post(name: .fiatCurrencySelected, object: nil)
                    self.recordingProvider.analytics.record(event: AnalyticsEvent.sbCurrencySelected(currencyCode: value.0.code))
                    
                    let isFiatCurrencySupported = value.1
                    let currency = value.0
                    
                    self.navigationRouter.dismiss {
                        self.stateService.previousRelay.accept(())
                        if !isFiatCurrencySupported {
                            self.stateService.ineligible(with: currency)
                        } else {
                            self.stateService.currencySelected()
                        }
                    }
                })
            .disposed(by: disposeBag)
    }
    
    private func showPaymentMethodsScreen() {
        let interactor = PaymentMethodsScreenInteractor(
            paymentMethodTypesService: serviceProvider.paymentMethodTypes,
            fiatCurrencyService: serviceProvider.settings,
            kycTiers: kycServiceProvider.tiers
        )
        let presenter = PaymentMethodsScreenPresenter(
            interactor: interactor,
            stateService: stateService,
            eventRecorder: recordingProvider.analytics
        )
        let viewController = PaymentMethodsScreenViewController(presenter: presenter)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationRouter.navigationControllerAPI?.present(navigationController, animated: true, completion: nil)
    }
    
    private func showInelligibleCurrency(with currency: FiatCurrency) {
        let presenter = IneligibleCurrencyScreenPresenter(
            currency: currency,
            stateService: stateService,
            analyticsRecording: recordingProvider.analytics
        )
        let controller = IneligibleCurrencyViewController(presenter: presenter)
        controller.transitioningDelegate = sheetPresenter
        controller.modalPresentationStyle = .custom
        recordingProvider.analytics.record(event: AnalyticsEvent.sbCurrencyUnsupported)
        navigationRouter.topMostViewControllerProvider.topMostViewController?.present(controller, animated: true, completion: nil)
    }
    
    /// Shows the checkout details screen
    private func showBankTransferDetailScreen(with data: CheckoutData) {
        let interactor = BankTransferDetailScreenInteractor(
            checkoutData: data,
            cancellationService: serviceProvider.orderCancellation
        )
        
        let webViewRouter = WebViewRouter(
            topMostViewControllerProvider: navigationRouter.topMostViewControllerProvider
        )
        
        let presenter = BankTransferDetailScreenPresenter(
            webViewRouter: webViewRouter,
            analyticsRecorder: recordingProvider.analytics,
            interactor: interactor,
            stateService: stateService
        )
        let viewController = DetailsScreenViewController(presenter: presenter)
        navigationRouter.present(viewController: viewController)
    }
    
    private func showFundsTransferDetailsScreen(with fiatCurrency: FiatCurrency, shouldDismissModal: Bool, isOriginDeposit: Bool) {
        let viewController = builder.fundsTransferDetailsViewController(for: fiatCurrency, isOriginDeposit: isOriginDeposit)
        if shouldDismissModal {
            navigationRouter.topMostViewControllerProvider.topMostViewController?.dismiss(animated: true) { [weak self] in
                self?.navigationRouter.navigationControllerAPI?.present(viewController, animated: true, completion: nil)
            }
        } else {
            navigationRouter.present(viewController: viewController, using: .modalOverTopMost)
        }
    }
    
    /// Shows the cancellation modal
    private func showTransferCancellation(with data: CheckoutData) {
        let interactor = TransferCancellationInteractor(
            checkoutData: data,
            cancellationService: serviceProvider.orderCancellation
        )
        
        let presenter = TransferCancellationScreenPresenter(
            stateService: stateService,
            currency: data.cryptoCurrency,
            analyticsRecorder: recordingProvider.analytics,
            interactor: interactor
        )
        let viewController = TransferCancellationViewController(presenter: presenter)
        viewController.transitioningDelegate = sheetPresenter
        viewController.modalPresentationStyle = .custom
        navigationRouter.topMostViewControllerProvider.topMostViewController?.present(viewController, animated: true, completion: nil)
    }
    
    /// Shows the checkout screen
    private func showCheckoutScreen(with data: CheckoutData) {
        
        let orderInteractor = OrderCheckoutInteractor(
            fundsAndBankInteractor: FundsAndBankOrderCheckoutInteractor(
                paymentAccountService: serviceProvider.paymentAccount,
                orderQuoteService: serviceProvider.orderQuote,
                orderCreationService: serviceProvider.orderCreation
            ),
            cardInteractor: CardOrderCheckoutInteractor(
                cardListService: cardServiceProvider.cardList,
                orderQuoteService: serviceProvider.orderQuote,
                orderCreationService: serviceProvider.orderCreation
            )
        )

        let interactor = CheckoutScreenInteractor(
            cardListService: cardServiceProvider.cardList,
            confirmationService: serviceProvider.orderConfirmation,
            cancellationService: serviceProvider.orderCancellation,
            orderCheckoutInterator: orderInteractor,
            checkoutData: data
        )
        let presenter = CheckoutScreenPresenter(
            stateService: stateService,
            analyticsRecorder: recordingProvider.analytics,
            interactor: interactor
        )
        let viewController = DetailsScreenViewController(presenter: presenter)
        navigationRouter.present(viewController: viewController)
    }
    
    private func showPendingOrderCompletionScreen(for orderId: String, cryptoValue: CryptoValue) {
        let interactor = PendingOrderStateScreenInteractor(
            orderId: orderId,
            amount: cryptoValue,
            service: serviceProvider.orderCompletion
        )
        let presenter = PendingOrderStateScreenPresenter(
            stateService: stateService,
            analyticsRecorder: recordingProvider.analytics,
            interactor: interactor
        )
        let viewController = PendingStateViewController(
            presenter: presenter
        )
        navigationRouter.present(viewController: viewController)
    }
    
    private func showCardAuthorization(with data: OrderDetails) {
        
        let interactor = CardAuthorizationScreenInteractor(
            routingInteractor: stateService
        )
        
        let presenter = CardAuthorizationScreenPresenter(
            interactor: interactor,
            data: data.authorizationData!,
            eventRecorder: recordingProvider.analytics
        )
        let viewController = CardAuthorizationScreenViewController(
            presenter: presenter
        )
        navigationRouter.present(viewController: viewController)
    }

    /// Show the pending kyc screen
    private func showPendingKycApprovalScreen() {
        let interactor = KYCPendingInteractor(
            kycTiersService: kycServiceProvider.tiersPollingService,
            eligibilityService: serviceProvider.eligibility
        )
        let presenter = KYCPendingPresenter(
            stateService: stateService,
            interactor: interactor,
            analyticsRecorder: recordingProvider.analytics
        )
        let viewController = PendingStateViewController(presenter: presenter)
        navigationRouter.present(viewController: viewController, using: .navigationFromCurrent)
    }
    
    private func showKYC(afterDismissal: Bool) {
        guard let kycRootViewController = navigationRouter.navigationControllerAPI as? UIViewController else {
            return
        }
        
        kycDisposeBag = DisposeBag()
        let stopped = kycRouter.kycStopped
            .take(1)
            .observeOn(MainScheduler.instance)
            .share()
        
        stopped
            .filter { $0 == .tier2 }
            .mapToVoid()
            .bindAndCatch(to: stateService.nextRelay)
            .disposed(by: kycDisposeBag)
        
        stopped
            .filter { $0 != .tier2 }
            .mapToVoid()
            .bindAndCatch(to: stateService.previousRelay)
            .disposed(by: kycDisposeBag)
        
        if afterDismissal {
            navigationRouter.topMostViewControllerProvider.topMostViewController?.dismiss(animated: true) { [weak self] in
                self?.kycRouter.start(from: kycRootViewController, tier: .tier2, parentFlow: .simpleBuy)
            }
        } else {
            kycRouter.start(from: kycRootViewController, tier: .tier2, parentFlow: .simpleBuy)
        }
    }
    
    /// Shows buy-crypto screen using a specified presentation type
    private func showBuyCryptoScreen() {
        let interactor = BuyCryptoScreenInteractor(
            kycTiersService: kycServiceProvider.tiers,
            exchangeProvider: exchangeProvider,
            fiatCurrencyService: serviceProvider.settings,
            cryptoCurrencySelectionService: cryptoSelectionService,
            pairsService: serviceProvider.supportedPairsInteractor,
            eligibilityService: serviceProvider.eligibility,
            paymentMethodTypesService: serviceProvider.paymentMethodTypes,
            orderCreationService: serviceProvider.orderCreation,
            suggestedAmountsService: serviceProvider.suggestedAmounts
        )

        let presenter = BuyCryptoScreenPresenter(
            analyticsRecorder: recordingProvider.analytics,
            router: self,
            stateService: stateService,
            interactor: interactor
        )
        let viewController = EnterAmountScreenViewController(presenter: presenter)
        
        navigationRouter.present(viewController: viewController)
    }

    /// Shows intro screen using a specified presentation type
    private func showIntroScreen() {
        let presenter = BuyIntroScreenPresenter(
            stateService: stateService,
            recordingProvider: recordingProvider
        )
        let viewController = BuyIntroScreenViewController(presenter: presenter)
        navigationRouter.present(viewController: viewController)
    }
    
    private lazy var sheetPresenter: BottomSheetPresenting = {
        BottomSheetPresenting(ignoresBackroundTouches: true)
    }()
}
