//
//  PlanService.swift
//  vpncore - Created on 01.09.2021.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of LegacyCommon.
//
//  vpncore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  vpncore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with LegacyCommon.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import Dependencies
import ProtonCoreDataModel
import ProtonCorePayments
import ProtonCorePaymentsUI
import LegacyCommon
import UIKit
import VPNShared
import Modals_iOS
import Modals
import CommonNetworking
import VPNAppCore

protocol PlanServiceFactory {
    func makePlanService() -> PlanService
}

protocol PlanServiceDelegate: AnyObject {
    @MainActor
    func paymentTransactionDidFinish(modalSource: UpsellModalSource?, newPlanName: String?) async
}

protocol PlanService {
    var allowUpgrade: Bool { get }
    var countriesCount: Int { get }
    var delegate: PlanServiceDelegate? { get set }
    var payments: Payments { get }

    func presentPlanSelection(modalSource: UpsellModalSource?)
    func presentSubscriptionManagement()
    func updateServicePlans() async throws
    func createPlusPlanUI(completion: @escaping () -> Void)

    func clear()
}

extension PlanService {
    func presentPlanSelection() {
        presentPlanSelection(modalSource: nil)
    }
}

final class CorePlanService: PlanService {
    @Dependency(\.serverRepository) var serverRepository
    private var paymentsUI: PaymentsUI?
    let payments: Payments
    private let alertService: CoreAlertService
    private let authKeychain: AuthKeychainHandle
    private let userCachedStatus: UserCachedStatus

    var countriesCount: Int {
        serverRepository.countryCount()
    }

    let tokenStorage: PaymentTokenStorage?

    weak var delegate: PlanServiceDelegate?

    var allowUpgrade: Bool {
        return userCachedStatus.paymentsBackendStatusAcceptsIAP
    }

    public typealias Factory = NetworkingFactory &
        CoreAlertServiceFactory &
        AuthKeychainHandleFactory

    public convenience init(_ factory: Factory) {
        self.init(networking: factory.makeNetworking(),
                  alertService: factory.makeCoreAlertService(),
                  authKeychain: factory.makeAuthKeychainHandle())
    }

    init(networking: Networking, alertService: CoreAlertService, authKeychain: AuthKeychainHandle) {
        self.alertService = alertService
        self.authKeychain = authKeychain

        tokenStorage = TokenStorage()
        userCachedStatus = UserCachedStatus()
        payments = Payments(
            inAppPurchaseIdentifiers: ObfuscatedConstants.vpnIAPIdentifiers,
            apiService: networking.apiService,
            localStorage: userCachedStatus,
            reportBugAlertHandler: { receipt in
                log.error("Error from payments, showing bug report", category: .iap)
                alertService.push(alert: ReportBugAlert())
            }
        )
    }

    func updateServicePlans() async throws {
        await payments.startObservingPaymentQueue(delegate: self)
        try await payments.updateServiceIAPAvailability()
    }

    func presentPlanSelection(modalSource: UpsellModalSource?) {
        guard userCachedStatus.paymentsBackendStatusAcceptsIAP else {
            alertService.push(alert: UpgradeUnavailableAlert())
            return
        }

        paymentsUI = createPaymentsUI()
        paymentsUI?.showCurrentPlan(presentationType: PaymentsUIPresentationType.modal, backendFetch: true) { [weak self] response in
            self?.handlePaymentsResponse(response: response, modalSource: modalSource)
        }
    }

    func presentSubscriptionManagement() {
        paymentsUI = createPaymentsUI()
        paymentsUI?.showCurrentPlan(presentationType: PaymentsUIPresentationType.modal, backendFetch: true) { [weak self] response in
            self?.handlePaymentsResponse(response: response, modalSource: nil)
        }
    }

    func createPlusPlanUI(completion: @escaping () -> Void) {
        paymentsUI = createPaymentsUI(onlyPlusPlan: true)
        paymentsUI?.showUpgradePlan(presentationType: PaymentsUIPresentationType.modal, backendFetch: true) { [weak self] response in
            switch response {
            case let .purchasedPlan(accountPlan: plan):
                log.debug("Purchased plan: \(plan.protonName)", category: .iap)
                completion()
                Task { [weak self] in
                    await self?.delegate?.paymentTransactionDidFinish(modalSource: nil, newPlanName: plan.protonName)
                }
            case let .purchaseError(error: error):
                log.error("Purchase failed", category: .iap, metadata: ["error": "\(error)"])
            case .close:
                log.debug("Payments closed", category: .iap)
            case let .planPurchaseProcessingInProgress(accountPlan: plan):
                log.debug("Purchasing \(plan.protonName)", category: .iap)
            case .toppedUpCredits:
                log.debug("Credits topped up", category: .iap)
            case let .apiMightBeBlocked(message, error):
               log.error("\(message)", category: .connection, metadata: ["error": "\(error)"])
            case .open:
                log.debug("Purchase screen opened", category: .iap)
            }
        }
    }

    func clear() {
        tokenStorage?.clear()
        userCachedStatus.clear()
    }

    private func createPaymentsUI(onlyPlusPlan: Bool = false) -> PaymentsUI {
        let plusPlanNames = ["vpnplus", "vpn2022"]
        let planNames = onlyPlusPlan ? ObfuscatedConstants.planNames.filter({ plusPlanNames.contains($0) }) : ObfuscatedConstants.planNames
        return PaymentsUI(payments: payments,
                          clientApp: ClientApp.vpn,
                          shownPlanNames: planNames,
                          customization: .init(inAppTheme: { .dark }))
    }

    private func handlePaymentsResponse(response: PaymentsUIResultReason, modalSource: UpsellModalSource?) {
        switch response {
        case let .purchasedPlan(accountPlan: plan):
            log.debug("Purchased plan: \(plan.protonName)", category: .iap)
            Task { [weak self] in
                await self?.delegate?.paymentTransactionDidFinish(modalSource: modalSource, newPlanName: plan.protonName)
            }
        case let .open(vc: _, opened: opened):
            assert(opened == true)
        case let .planPurchaseProcessingInProgress(accountPlan: plan):
            log.debug("Purchasing \(plan.protonName)", category: .iap)
        case .close:
            log.debug("Payments closed", category: .iap)
        case let .purchaseError(error: error):
            log.error("Purchase failed", category: .iap, metadata: ["error": "\(error)"])
        case .toppedUpCredits:
            log.debug("Credits topped up", category: .iap)
        case let .apiMightBeBlocked(message, originalError: error):
            log.error("\(message)", category: .connection, metadata: ["error": "\(error)"])

        }
    }
}

extension CorePlanService: StoreKitManagerDelegate {
    var isUnlocked: Bool {
        return true
    }

    var isSignedIn: Bool {
        authKeychain.username != nil
    }

    var activeUsername: String? {
        authKeychain.username
    }

    var userId: String? {
        authKeychain.userId
    }
}
