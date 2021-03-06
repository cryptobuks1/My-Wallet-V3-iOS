//
//  UserDefaults.swift
//  Blockchain
//
//  Created by Maurice A. on 4/13/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//
// Please keep the keys sorted alphabetically (:

import DIKit
import ToolKit

extension UserDefaults {

    // TICKET: IOS-1289 - Refactor key-value mapping such that key = value
    // Refactor simulateZeroTicker, shouldHideBuySellCard,
    // swipeToReceiveEnabled such that key = value (where possible)
    enum DebugKeys: String {
        case appReviewPromptCount = "debug_appReviewPromptCount"
        case securityReminderTimer = "debug_securiterReminderTimer"
        case simulateSurge = "debug_simulateSurge"
        case simulateZeroTicker = "debug_zeroTicker"
        case createWalletPrefill = "debug_createWalletPrefill"
        case createWalletEmailPrefill = "debug_createWalletEmailPrefill"
        case createWalletEmailRandomSuffix = "debug_createWalletEmailRandomSuffix"
        case useHomebrewForExchange = "debug_useHomebrewForExchange"
        case mockExchangeOrderDepositAddress = "debug_mockExchangeOrderDepositAddress"
        case mockExchangeDeposit = "debug_mockExchangeDeposit"
        case mockExchangeDepositQuantity = "debug_mockExchangeDepositQuantity"
        case mockExchangeDepositAssetTypeString = "debug_mockExchangeDepositAssetTypeString"
    }

    enum Keys: String {
        case appBecameActiveCount
        case biometryEnabled
        case defaultAccountLabelledAddressesCount
        case dontAskUserToShowAppReviewPrompt
        case encryptedPinPassword
        // legacyEncryptedPinPassword is required for wallets that created a PIN prior to Homebrew release - see IOS-1537
        case legacyEncryptedPinPassword = "encryptedPINPassword"
        case firstRun
        case graphTimeFrameKey = "timeFrame"
        case hasEndedFirstSession
        case password
        case passwordPartHash
        case pin
        case pinKey
        case isCompletingKyc = "shouldShowKYCAnnouncementCard"
        case didTapOnAirdropDeepLink
        case swipeToReceiveEnabled = "swipeToReceive"
        case cloudBackupEnabled
        case selectedLegacyAssetType = "assetType"
        case symbolLocal
        case hasSeenAirdropJoinWaitlistCard
        case hasSeenGetFreeXlmModal
        case didAttemptToRouteForAirdrop
        case didRegisterForAirdropCampaignSucceed
        case kycLatestPage
        case didRequestCameraPermissions
        case didRequestMicrophonePermissions
        case didRequestNotificationPermissions
        case didTapOnKycDeepLink
        case didTapOnDocumentResubmissionDeepLink
        case documentResubmissionLinkReason
        case exchangeLinkIdentifier = "pitLinkIdentifier"
        case didTapOnExchangeDeepLink = "didTapOnPitDeepLink"
        case walletIntroLatestLocation
        case custodySendInterstitialViewed
    }
}

extension CacheSuite {
    func migrateLegacyKeysIfNeeded() {
        migrateBool(fromKey: "touchIDEnabled", toKey: UserDefaults.Keys.biometryEnabled.rawValue)
    }

    private func migrateBool(fromKey: String, toKey: String) {
        guard let value = object(forKey: fromKey) as? Bool else { return }
        self.set(value, forKey: toKey)
        self.removeObject(forKey: fromKey)
    }
}
