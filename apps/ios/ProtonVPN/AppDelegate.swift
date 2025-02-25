//
//  AppDelegate.swift
//  ProtonVPN - Created on 01.07.19.
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

// System frameworks
import UIKit
import Foundation

// Third-party dependencies
import Dependencies
import TrustKit

// Core dependencies
import ProtonCoreAccountRecovery
import ProtonCoreCryptoVPNPatchedGoImplementation
import ProtonCoreEnvironment
import ProtonCoreFeatureFlags
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCorePushNotifications
import ProtonCoreServices
import ProtonCoreUIFoundations
import ProtonCoreTelemetry

// Local dependencies
import Domain
import Ergonomics
import LegacyCommon
import Logging
import PMLogger
import VPNShared
import VPNAppCore

public let log: Logging.Logger = Logging.Logger(label: "ProtonVPN.logger")

final class AppDelegate: UIResponder {
    private static let acceptedDeepLinkChallengeInterval: TimeInterval = 10

    @Dependency(\.defaultsProvider) var defaultsProvider
    @Dependency(\.cryptoService) var cryptoService

    private let container = DependencyContainer.shared
    private lazy var vpnManager: VpnManagerProtocol = container.makeVpnManager()
    private lazy var appSessionManager: AppSessionManager = container.makeAppSessionManager()
    private lazy var vpnKeychain: VpnKeychainProtocol = container.makeVpnKeychain()
    private lazy var navigationService: NavigationService = container.makeNavigationService()
    private lazy var propertiesManager: PropertiesManagerProtocol = container.makePropertiesManager()
    private lazy var appStateManager: AppStateManager = container.makeAppStateManager()
    private lazy var planService: PlanService = container.makePlanService()
    private lazy var telemetrySettings: TelemetrySettings = container.makeTelemetrySettings()
    private lazy var pushNotificationService = container.makePushNotificationService()

    private var tokens: [NotificationToken] = []

    override init() {
        super.init()
        // WARNING: Be sure `setUpNSCoding` is run before there is a slight chance that we'll be decoding ANYTHING.
        // Force all encoded objects to be decoded and recoded using the ProtonVPN module name
        setUpNSCoding(withModuleName: "ProtonVPN")
    }
}

// MARK: - UIApplicationDelegate
extension AppDelegate: UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        #if DEBUG
        #if targetEnvironment(simulator)
        // Force log out if running UI tests
        if ProcessInfo.processInfo.arguments.contains("UITests") {
            appSessionManager.logOut(force: false, reason: "UI tests")
        }
        #endif
        #endif

        // Clear out any overrides that may have been present in previous builds
        FeatureFlagsRepository.shared.resetOverrides()

        FeatureFlagsRepository.shared.setFlagOverride(CoreFeatureFlagType.dynamicPlan, true)
//      Safety measure to not accidentally switch on the redesign before it's ready
//      FeatureFlagsRepository.shared.setFlagOverride(VPNFeatureFlagType.redesigniOS, true)

        setupCoreIntegration(launchOptions: launchOptions)
        setupLogsForApp()
        setupDebugHelpers()

        // Make sure AppStateManager is ready and is created on the main thread
        _ = appStateManager

        SiriHelper.quickConnectIntent = QuickConnectIntent()
        SiriHelper.disconnectIntent = DisconnectIntent()
        LegacyDefaultsMigration.migrateLargeData(from: defaultsProvider.getDefaults())

        // Protocol check is placed here for parity with MacOS
        adjustGlobalProtocolIfNecessary()

        // Sentry turned off, because https://github.com/getsentry/sentry-cocoa/issues/1892
        // is still not fixed.
//        if FeatureFlagsRepository.shared.isEnabled(VPNFeatureFlagType.sentry) {
//            SentryHelper.setupSentry(
//                dsn: ObfuscatedConstants.sentryDsniOS,
//                isEnabled: { [weak self] in
//                    self?.isTelemetryAllowed() ?? false
//                },
//                getUserId: { [weak self] in
//                    self?.container.makeAuthKeychainHandle().userId
//                }
//            )
//        }

        AnnouncementButtonViewModel.shared = container.makeAnnouncementButtonViewModel()
        if FeatureFlagsRepository.shared.isEnabled(VPNFeatureFlagType.asyncVPNManager) {
            Task { @MainActor in
                await vpnManager.prepareManagersTask?.value
                self.navigationService.launched()
            }
        } else {
            vpnManager.whenReady(queue: DispatchQueue.main) {
                self.navigationService.launched()
            }
        }

        container.makeMaintenanceManagerHelper().startMaintenanceManager()

        _ = container.makeDynamicBugReportManager() // Loads initial bug report config and sets up a timer to refresh it daily.

        container.applicationDidFinishLaunching()

        registerForTelemetryChanges()

        return true
    }

    private func setupDebugHelpers() {
        #if FREQUENT_AUTH_CERT_REFRESH
        CertificateConstants.certificateDuration = "30 minutes"
        #endif
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        appStateManager.refreshState()
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Handle Siri intents
        let prefix = "com.protonmail.vpn."
        guard userActivity.activityType.hasPrefix(prefix) else {
            return false
        }

        let action = String(userActivity.activityType.dropFirst(prefix.count))

        // We know the action is verified because the user activity has our prefix.
        let verified = true
        return handleAction(action, verified: verified)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            log.error("Invalid URL", category: .app)
            return false
        }

        let verified = isVerifiedUrl(components)
        return handleAction(host, verified: verified)
    }

    func isVerifiedUrl(_ components: URLComponents) -> Bool {
        guard let queryItems = components.queryItems,
              let t = queryItems.first(where: { $0.name == "t" })?.value,
              var timestamp = Int(t) else {
            return false
        }

        let timestampDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let interval = Date().timeIntervalSince(timestampDate)
        guard interval < Self.acceptedDeepLinkChallengeInterval else {
            return false
        }

        let algorithm = CryptoConstants.widgetChallengeAlgorithm
        guard let s = queryItems.first(where: { $0.name == "s" })?.value?.data(using: .utf8),
           let a = queryItems.first(where: { $0.name == "a" })?.value,
               a == algorithm.stringValue,
           let signature = Data(base64Encoded: s) else {
            return false
        }

        let challenge = withUnsafeBytes(of: &timestamp) { Data($0) }

        do {
            let publicKey = try vpnKeychain.fetchWidgetPublicKey()
            if try cryptoService.verify(signature: signature, of: challenge, with: publicKey, using: algorithm) {
                return true
            }
        } catch {
            log.error("Couldn't verify url: \(error)")
        }

        log.error("Verification of url failed: \(components)")
        return false
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        log.info("applicationDidEnterBackground", category: .os)
        vpnManager.appBackgroundStateDidChange(isBackground: true)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        log.info("applicationDidBecomeActive", category: .os)
        vpnManager.appBackgroundStateDidChange(isBackground: false)

        // Refresh API announcements
        let announcementRefresher = self.container.makeAnnouncementRefresher() // This creates refresher that is persisted in DI container
        if propertiesManager.featureFlags.pollNotificationAPI, container.makeAuthKeychainHandle().username != nil {
            announcementRefresher.tryRefreshing()
        }
        Task { @MainActor in
            try? await container.makeAppSessionManager().refreshVpnAuthCertificate()
            container.makeReview().activated()
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        pushNotificationService.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        pushNotificationService.didFailToRegisterForRemoteNotifications(withError: error)
    }

    private func setupLogsForApp() {
        let logFile = self.container.makeLogFileManager().getFileUrl(named: AppConstants.Filenames.appLogFilename)

        let fileLogHandler = FileLogHandler(logFile)
        let osLogHandler = OSLogHandler(formatter: OSLogFormatter())
        let multiplexLogHandler = MultiplexLogHandler([osLogHandler, fileLogHandler])

        LoggingSystem.bootstrap { _ in return multiplexLogHandler }
    }
}

fileprivate extension AppDelegate {

    // MARK: - Private

    func handleAction(_ action: String, verified: Bool = false) -> Bool {
        switch action {

        case URLConstants.deepLinkLoginAction:
            DispatchQueue.main.async { [weak self] in
                self?.navigationService.presentWelcome(initialError: nil)
            }

        case URLConstants.deepLinkConnectAction:
            // Action may only come from a trusted source
            guard verified else { return false }

            // Extensions requesting a connection should set a connection request first
            navigationService.vpnGateway.quickConnect(trigger: .widget)
            NotificationCenter.default.addObserver(self, selector: #selector(stateDidUpdate), name: VpnGateway.connectionChanged, object: nil)
            navigationService.presentStatusViewController()

        case URLConstants.deepLinkDisconnectAction:
            // Action may only come from a trusted source
            guard verified else { return false }

            NotificationCenter.default.post(name: .userInitiatedVPNChange, object: UserInitiatedVPNChange.disconnect(.widget))
            navigationService.vpnGateway.disconnect {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
                }
            }

        case URLConstants.deepLinkRefresh, URLConstants.deepLinkRefreshAccount:
            guard container.makeAuthKeychainHandle().username != nil else {
                log.debug("User is not logged in, not refreshing user data", category: .app)
                return false
            }

            log.debug("App activated with the refresh url, refreshing data", category: .app)
            container.makeAppSessionManager().attemptSilentLogIn { result in
                switch result {
                case .success:
                    log.debug("User data refreshed after url activation", category: .app)
                case let .failure(error):
                    log.error("User data failed to refresh after url activation", category: .app, metadata: ["error": "\(error)"])
                }
            }
            NotificationCenter.default.post(name: PropertiesManager.announcementsNotification, object: nil)

        default:
            log.error("Invalid url action", category: .app, metadata: ["action": "\(action)"])
            return false
        }

        return true
    }

    @objc func stateDidUpdate() {
        switch appStateManager.state {
        case .connected:
            NotificationCenter.default.removeObserver(self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
            }
        case .connecting, .preparingConnection:
            // wait
            return
        default:
            NotificationCenter.default.removeObserver(self)
            return
        }
    }

    private func adjustGlobalProtocolIfNecessary() {
        if propertiesManager.connectionProtocol.isDeprecated {
            propertiesManager.connectionProtocol = .smartProtocol
        }
    }
}

extension AppDelegate {
    // Typically set the environment only if telemetry is allowed
    private func enableExternalLogging() {
        @Dependency(\.dohConfiguration) var doh
        if doh.defaultHost.contains(PMLog.ExternalLogEnvironment.black.rawValue) {
            PMLog.setExternalLoggingEnvironment(.black)
        } else {
            PMLog.setExternalLoggingEnvironment(.production)
        }
    }

    private func disableExternalLogging() {
        PMLog.disableExternalLogging()
    }

    private func setupCoreIntegration(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        injectDefaultCryptoImplementation()

        ProtonCoreLog.PMLog.callback = { (message, level) in
            switch level {
            case .debug, .info, .trace, .warn:
                log.debug("\(message)", category: .core)
            case .error, .fatal:
                log.error("\(message)", category: .core)
            }
        }

        let apiService = container.makeNetworking().apiService
        apiService.acquireSessionIfNeeded { [unowned apiService, unowned self] result in
            switch result {
            case .success(.sessionAlreadyPresent(let authCredential)), .success(.sessionFetchedAndAvailable(let authCredential)):
                FeatureFlagsRepository.shared.setApiService(apiService)

                if !authCredential.userID.isEmpty {
                    FeatureFlagsRepository.shared.setUserId(authCredential.userID)
                }

                Task { [self] in
                     do {
                        try await FeatureFlagsRepository.shared.fetchFlags()
                        self.registerForPushNotificationsIfNeeded()
                    } catch {
                        log.error("Could not retrieve feature flags: \(error)", category: .core, event: .error)
                    }
                }

                TelemetryService.shared.setApiService(apiService: apiService)
                TelemetryService.shared.setTelemetryEnabled(telemetrySettings.telemetryUsageData)

                let isTelemetryEnabled = self.telemetrySettings.telemetryCrashReports

                if isTelemetryEnabled {
                    enableExternalLogging()
                } else {
                    disableExternalLogging()
                }
            case .failure(let error):
                log.error("acquireSessionIfNeeded didn't succeed and therefore feature flags didn't get fetched", category: .api, event: .response, metadata: ["error": "\(error)"])
            default:
                break
            }
        }
        ObservabilityEnv.current.setupWorld(requestPerformer: apiService)
    }

    private func registerForTelemetryChanges() {
        let center = NotificationCenter.default
        tokens.append(
            center.addObserver(for: PropertiesManager.telemetryCrashReportsNotification, object: nil) { [weak self] notification in
                switch (notification.object as? Bool) {
                case true:
                    self?.enableExternalLogging()
                case false:
                    self?.disableExternalLogging()
                default:
                    break // unknown object type, not doing anything
                }
            }
        )
    }

    private func registerForPushNotificationsIfNeeded() {
        if FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.pushNotifications) {
            pushNotificationService.setup()

            if FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.accountRecovery) {
                let vpnHandler = AccountRecoveryHandler()
                vpnHandler.handler = { [weak self] _ in
                    // for now, for all notification types, we take the same action
                    self?.navigationService.presentAccountRecoveryViewController()
                    return .success(())
                }

                NotificationType.allAccountRecoveryTypes.forEach {
                    pushNotificationService.registerHandler(vpnHandler, forType: $0)
                }
            }
        }
    }
}
