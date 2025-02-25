//
//  IosCoreAlertService.swift
//  ProtonVPN - Created on 09/09/2019.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonVPN.
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.
//

import Ergonomics
import Foundation
import LegacyCommon
import Modals
import Modals_iOS
import UIKit
import ProtonCoreUIFoundations
import Strings
import Dependencies
import Persistence
import VPNAppCore

final class IosAlertService {
        
    typealias Factory = UIAlertServiceFactory &
        AppSessionManagerFactory &
        WindowServiceFactory &
        SettingsServiceFactory &
        TroubleshootCoordinatorFactory &
        SafariServiceFactory &
        PlanServiceFactory &
        SessionServiceFactory

    private let factory: Factory
    
    private lazy var uiAlertService: UIAlertService = factory.makeUIAlertService()
    private lazy var appSessionManager: AppSessionManager = factory.makeAppSessionManager()
    private lazy var windowService: WindowService = factory.makeWindowService()
    private lazy var settingsService: SettingsService = factory.makeSettingsService()
    private lazy var safariService: SafariServiceProtocol = factory.makeSafariService()

    private lazy var planService: PlanService = factory.makePlanService()
    private lazy var modalsFactory: ModalsFactory = ModalsFactory()

    private var oneClickPayment: OneClickPayment?

    @ConcurrentlyReadable
    private var upsellAlerts: [UUID: UpsellAlert] = [:]

    init(_ factory: Factory) {
        self.factory = factory
    }
}

extension IosAlertService: CoreAlertService {

    func push(alert: SystemAlert) {
        executeOnUIThread {
            self.pushOnUIThread(alert: alert)
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    func pushOnUIThread(alert: SystemAlert) {
        log.debug("Alert shown: \(String(describing: type(of: alert)))", category: .ui)

        switch alert {
        case is AccountDeletionErrorAlert:
            showDefaultSystemAlert(alert)
            
        case is AccountDeletionWarningAlert:
            showDefaultSystemAlert(alert)
            
        case let appUpdateRequiredAlert as AppUpdateRequiredAlert:
            show(appUpdateRequiredAlert)
            
        case let cannotAccessVpnCredentialsAlert as CannotAccessVpnCredentialsAlert:
            show(cannotAccessVpnCredentialsAlert)

        case is P2pBlockedAlert:
            showDefaultSystemAlert(alert)
            
        case is P2pForwardedAlert:
            showDefaultSystemAlert(alert)
            
        case let refreshTokenExpiredAlert as RefreshTokenExpiredAlert:
            show(refreshTokenExpiredAlert)
            
        case is UpgradeUnavailableAlert:
            showDefaultSystemAlert(alert)
            
        case is DelinquentUserAlert:
            showDefaultSystemAlert(alert)
            
        case is VpnStuckAlert:
            showDefaultSystemAlert(alert)
            
        case is VpnNetworkUnreachableAlert:
            showNotificationStyleAlert(message: alert.title ?? alert.message ?? "")
            
        case is MaintenanceAlert:
            showDefaultSystemAlert(alert)
            
        case is SecureCoreToggleDisconnectAlert:
            showDefaultSystemAlert(alert)
            
        case is ChangeProtocolDisconnectAlert:
            showDefaultSystemAlert(alert)
            
        case is LogoutWarningAlert:
            showDefaultSystemAlert(alert)

        case is BugReportSentAlert:
            showDefaultSystemAlert(alert)
            
        case let reportBugAlert as ReportBugAlert:
            show(reportBugAlert)

        case is MITMAlert:
            showDefaultSystemAlert(alert)
            
        case is UnreachableNetworkAlert:
            showDefaultSystemAlert(alert)
            
        case let connectionTroubleshootingAlert as ConnectionTroubleshootingAlert:
            show(connectionTroubleshootingAlert)
            
        case is ReconnectOnNetshieldChangeAlert:
            showDefaultSystemAlert(alert)

        case let vpnServerOnMaintenanceAlert as VpnServerOnMaintenanceAlert:
            show(vpnServerOnMaintenanceAlert)

        case is VPNAuthCertificateRefreshErrorAlert:
            showDefaultSystemAlert(alert)
            
        case let alert as UserAccountUpdateAlert:
            displayUserUpdateAlert(alert: alert)

        case is ReconnectOnSmartProtocolChangeAlert:
            showDefaultSystemAlert(alert)
            
        case is ReconnectOnActionAlert:
            showDefaultSystemAlert(alert)

        case is VpnServerErrorAlert:
            showDefaultSystemAlert(alert)

        case is VpnServerSubscriptionErrorAlert:
            showDefaultSystemAlert(alert)
            
        case is AllowLANConnectionsAlert:
            showDefaultSystemAlert(alert)
            
        case is TurnOnKillSwitchAlert:
            showDefaultSystemAlert(alert)
            
        case is ReconnectOnSettingsChangeAlert:
            showDefaultSystemAlert(alert)

        case let announcementOfferAlert as AnnouncementOfferAlert:
            show(announcementOfferAlert)
            
        case let subuserAlert as SubuserWithoutConnectionsAlert:
            show(subuserAlert)
            
        case is TooManyCertificateRequestsAlert:
            showDefaultSystemAlert(alert)

        case let discourageAlert as DiscourageSecureCoreAlert:
            show(discourageAlert)
            
        case let safeModeUpsell as SafeModeUpsellAlert:
            show(alert: safeModeUpsell, modalType: .safeMode)

        case let netShieldUpsell as NetShieldUpsellAlert:
            show(alert: netShieldUpsell, modalType: .netShield)

        case let secureCoreUpsell as SecureCoreUpsellAlert:
            show(alert: secureCoreUpsell, modalType: .secureCore)

        case let moderateNatUpsell as ModerateNATUpsellAlert:
            show(alert: moderateNatUpsell, modalType: .moderateNAT)

        case let allCountriesUpsell as AllCountriesUpsellAlert:
            @Dependency(\.serverRepository) var repository
            let allCountriesModalType = ModalType.allCountries(
                numberOfServers: repository.roundedServerCount,
                numberOfCountries: repository.countryCount()
            )
            show(alert: allCountriesUpsell, modalType: allCountriesModalType)

        case let profilesUpsell as ProfilesUpsellAlert:
            show(alert: profilesUpsell, modalType: .profiles)

        case let vpnAcceleratorUpsell as VPNAcceleratorUpsellAlert:
            show(alert: vpnAcceleratorUpsell, modalType: .vpnAccelerator)

        case let customizationUpsell as CustomizationUpsellAlert:
            show(alert: customizationUpsell, modalType: .customization)

        case let countryUpsell as CountryUpsellAlert:
            @Dependency(\.serverRepository) var repository
            show(
                alert: countryUpsell,
                modalType: .country(
                    countryFlag: countryUpsell.countryFlag,
                    numberOfDevices: CoreAppConstants.maxDeviceCount,
                    numberOfCountries: repository.countryCount()
                )
            )
            
        case let alert as WelcomeScreenAlert:
            showWelcomeScreen(welcomeScreenAlert: alert)

        case is LocalAgentSystemErrorAlert:
            showDefaultSystemAlert(alert)

        case is ProtocolNotAvailableForServerAlert:
            showDefaultSystemAlert(alert)

        case is LocationNotAvailableAlert:
            showDefaultSystemAlert(alert)

        case is ProtocolDeprecatedAlert:
            showDefaultSystemAlert(alert)

        case is ConnectingWithBadLANAlert:
            showDefaultSystemAlert(alert)

        case let cooldownUpsell as ConnectionCooldownAlert:
            show(
                alert: cooldownUpsell,
                modalType: .cantSkip(
                    before: cooldownUpsell.until,
                    totalDuration: cooldownUpsell.duration,
                    longSkip: cooldownUpsell.longSkip
                )
            )

        case let alert as FreeConnectionsAlert:
            show(alert)

        case let alert as PaymentAlert:
            showDefaultSystemAlert(alert)

        case let alert as UpgradeOperatingSystemAlert:
            showDefaultSystemAlert(alert)

        default:
            #if DEBUG
            fatalError("Alert type handling not implemented: \(String(describing: alert))")
            #else
            showDefaultSystemAlert(alert)
            #endif
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    // This method translates the `UserAccountUpdateAlert` subclasses to specific feature types that the Modals module expects.
    private func displayUserUpdateAlert(alert: UserAccountUpdateAlert) {
        let server = alert.reconnectInfo?.servers()
        let viewModel: UserAccountUpdateViewModel
        switch alert {
        case is UserBecameDelinquentAlert:
            if let server = server {
                viewModel = .pendingInvoicesReconnecting(fromServer: server.from, toServer: server.to)
            } else {
                viewModel = .pendingInvoices
            }
        case is UserPlanDowngradedAlert:
            if let server = server {
                viewModel = .subscriptionDowngradedReconnecting(numberOfCountries: planService.countriesCount,
                                                                numberOfDevices: CoreAppConstants.maxDeviceCount,
                                                              fromServer: server.from,
                                                              toServer: server.to)
            } else {
                viewModel = .subscriptionDowngraded(numberOfCountries: planService.countriesCount,
                                                  numberOfDevices: CoreAppConstants.maxDeviceCount)
            }
        case let alert as MaxSessionsAlert:
            if alert.accountTier.isFreeTier {
                viewModel = .reachedDevicePlanLimit(planName: Localizable.plus, numberOfDevices: CoreAppConstants.maxDeviceCount)
            } else {
                viewModel = .reachedDeviceLimit
            }
        default:
            return
        }
        let onPrimaryButtonTap: (() -> Void)? = { [weak self] in
            self?.planService.presentPlanSelection()
        }

        let viewController = modalsFactory.userAccountUpdateViewController(viewModel: viewModel,
                                                                           onPrimaryButtonTap: onPrimaryButtonTap)
        viewController.modalPresentationStyle = .overFullScreen
        self.windowService.present(modal: viewController)
    }

    private func showWelcomeScreen(welcomeScreenAlert: WelcomeScreenAlert) {
        let modalType: ModalType
        switch welcomeScreenAlert.plan {
        case .fallback:
            modalType = .welcomeFallback
        case .unlimited:
            modalType = .welcomeUnlimited
        case let .plus(numberOfServers, numberOfDevices, numberOfCountries):
            modalType = .welcomePlus(
                numberOfServers: numberOfServers,
                numberOfDevices: numberOfDevices,
                numberOfCountries: numberOfCountries)
        }
        let viewController = modalsFactory.modalViewController(modalType: modalType, primaryAction: { [weak self] in
            self?.windowService.dismissModal(nil)
            NotificationCenter.default.post(name: .userDismissedWelcomeScreen, object: nil)
        })
        viewController.modalPresentationStyle = .overFullScreen
        windowService.present(modal: viewController)
    }

    private func show(alert: UpsellAlert, modalType: Modals.ModalType) {
        guard let oneClickPayment = OneClickPayment(
            alertService: self,
            planService: planService,
            payments: planService.payments
        ) else {
            // Can be disabled if `DynamicPlan` FF set to false, but this doesn't happen in practice (default is true).
            return
        }

        oneClickPayment.completionHandler = { [weak self] in
            self?.windowService.dismissModal(nil)
        }

        let viewController = modalsFactory.upsellViewController(
            modalType: modalType,
            client: oneClickPayment.plansClient(
                validationHandler: {
                    NotificationCenter.default.post(name: .userEngagedWithUpsellAlert, object: alert.modalSource)
                },
                notNowHandler: { [weak self] in
                    self?.windowService.dismissModal(nil)
                }
            )
        )
        viewController.modalPresentationStyle = .overFullScreen
        self.oneClickPayment = oneClickPayment

        windowService.present(modal: viewController)
        NotificationCenter.default.post(name: .upsellAlertWasDisplayed, object: alert.modalSource)
    }

    private func show(_ alert: DiscourageSecureCoreAlert) {
        let discourageSecureCoreViewController = modalsFactory.discourageSecureCoreViewController(onDontShowAgain: alert.onDontShowAgain, onActivate: alert.onActivate, onCancel: alert.dismiss, onLearnMore: alert.onLearnMore)
        windowService.present(modal: discourageSecureCoreViewController)
    }

    private func show(_ alert: AppUpdateRequiredAlert) {
        alert.actions.append(AlertAction(title: Localizable.ok, style: .confirmative, handler: { [weak self] in
            self?.appSessionManager.logOut(force: true, reason: nil)
        }))
        
        uiAlertService.displayAlert(alert)
    }
    
    private func show(_ alert: CannotAccessVpnCredentialsAlert) {
        guard appSessionManager.sessionStatus == .established else { return } // already logged out
        appSessionManager.logOut(force: true, reason: Localizable.errorSignInAgain)
    }
    
    private func show(_ alert: RefreshTokenExpiredAlert) {
        appSessionManager.logOut(force: true, reason: Localizable.invalidRefreshTokenPleaseLogin)
    }
    
    private func show(_ alert: MaintenanceAlert) {
        switch alert.type {
        case .alert:
            showDefaultSystemAlert(alert)
        case .notification:
            showNotificationStyleAlert(message: alert.title ?? alert.message ?? "")
        }
    }
    
    private func show(_ alert: ReportBugAlert) {
        settingsService.presentReportBug()
    }
    
    private func showDefaultSystemAlert(_ alert: SystemAlert) {
        if alert.actions.isEmpty {
            alert.actions.append(AlertAction(title: Localizable.ok, style: .confirmative, handler: nil))
        }
        self.uiAlertService.displayAlert(alert)
    }
    
    private func showNotificationStyleAlert(message: String, type: NotificationStyleAlertType = .error, accessibilityIdentifier: String? = nil) {
        uiAlertService.displayNotificationStyleAlert(message: message, type: type, accessibilityIdentifier: accessibilityIdentifier)
    }
    
    private func show(_ alert: ConnectionTroubleshootingAlert) {
        factory.makeTroubleshootCoordinator().start()
    }
 
    private func show(_ alert: VpnServerOnMaintenanceAlert ) {
        showNotificationStyleAlert(message: alert.title ?? "", type: .success)
    }

    private func show(_ alert: AnnouncementOfferAlert) {
        guard let panelMode = alert.data.panelMode() else {
            log.warning("Couldn't determine panelMode from: \(alert.data)")
            return
        }
        let announcement: AnnouncementViewController
        switch panelMode {
        case .legacy(let legacyPanel):
            announcement = AnnouncementDetailViewController(legacyPanel)
            announcement.modalPresentationStyle = .fullScreen
        case .image(let imagePanel):
            announcement = AnnouncementImageViewController(data: imagePanel, offerReference: alert.offerReference, sessionService: factory.makeSessionService())
            announcement.modalPresentationStyle = UIDevice.current.isIpad ? .pageSheet : .overFullScreen
        }
        announcement.cancelled = { [weak self] in
            self?.windowService.dismissModal { }
        }
        announcement.urlRequested = { [weak self] url in
            self?.safariService.open(url: url)

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .userEngagedWithAnnouncement, object: alert.offerReference)
            }
        }
        windowService.present(modal: announcement)
    }

    private func show(_ alert: SubuserWithoutConnectionsAlert) {
        let storyboard = UIStoryboard(name: "SubuserAlertViewController", bundle: Bundle.main)
        guard let controller = storyboard.instantiateInitialViewController() as? SubuserAlertViewController else { return }
        controller.role = alert.role
        controller.safariServiceFactory = factory
        windowService.present(modal: controller)
    }
    
    private func show(_ alert: FreeConnectionsAlert) {
        let upgradeAction: (() -> Void) = { [weak self] in
            self?.windowService.dismissModal {
                self?.planService.presentPlanSelection()
            }
        }

        let upsellViewController = modalsFactory.freeConnectionsViewController(countries: alert.countries, upgradeAction: upgradeAction)
        windowService.present(modal: upsellViewController)
    }
}

fileprivate extension ReconnectInfo {
    func servers() -> (from: (String, Image), to: (String, Image)) {
        ((fromServer.name, fromServer.image), (toServer.name, toServer.image))
    }
}
