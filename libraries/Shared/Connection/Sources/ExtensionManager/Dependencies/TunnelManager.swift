//
//  Created on 29/05/2024.
//
//  Copyright (c) 2024 Proton AG
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

import Foundation
import enum NetworkExtension.NEVPNStatus

import Dependencies

import struct Domain.ServerConnectionIntent
import let ConnectionFoundations.log
import struct ConnectionFoundations.LogicalServerInfo
import ExtensionIPC

protocol TunnelManager {
    func startTunnel(with intent: ServerConnectionIntent) async throws
    func stopTunnel() async throws
    func removeManagers() async throws

    var session: VPNSession { get async throws }
    var connectedServer: LogicalServerInfo { get async throws }
    var status: NEVPNStatus { get async throws }
    var statusStream: AsyncStream<NEVPNStatus> { get async throws }

}

@available(iOS 16, *)
enum TunnelManagerKey: DependencyKey {
#if targetEnvironment(simulator)
    static let liveValue: TunnelManager = {
        let mockSession = VPNSessionMock(status: .disconnected)
        mockSession.messageHandler = MessageHandler.full
        return MockTunnelManager(connection: mockSession)
    }()
#else
    static let liveValue: TunnelManager = PacketTunnelManager()
#endif
}

final class PacketTunnelManager: TunnelManager {
    @Dependency(\.tunnelProviderManagerFactory) var managerFactory
    @Dependency(\.tunnelProviderConfigurator) var configurator

    private var cachedLoadedManager: TunnelProviderManager?

    /// Creates and loads a new `TunnelProviderManager`.
    private func loadManager() async throws -> TunnelProviderManager {
        // TODO: Provide bundle ID using a Dependency
        let bundleID = "ch.protonmail.vpn.WireGuard-tvOS"
        let manager = try await managerFactory.loadManager(forProviderBundleID: bundleID)
        self.cachedLoadedManager = manager
        return manager
    }

    /// Returning a loaded manager is handy since actions like connecting and updating protocol settings require the
    /// manager to have been loaded at least once after the app has been launched.
    ///
    /// Relevant Apple Developer documentation:
    /// > You must call `loadFromPreferencesWithCompletionHandler` at least once before calling this method the first
    /// time after your app launches.
    /// > [saveToPreferences(completionHandler:)](https://developer.apple.com/documentation/networkextension/nevpnmanager/1405985-savetopreferences)
    private var loadedManager: TunnelProviderManager {
        get async throws {
            if let cachedLoadedManager {
                return cachedLoadedManager
            }

            return try await loadManager()
        }
    }

    private func updateTunnel(for operation: TunnelConfigurationOperation) async throws -> TunnelProviderManager {
        var manager = try await loadedManager
        try await configurator.configure(&manager, for: operation)
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        cachedLoadedManager = manager
        return manager
    }

    func startTunnel(with intent: ServerConnectionIntent) async throws {
        let manager = try await updateTunnel(for: .connection(intent))
        let session = manager.session
        try session.startTunnel()
    }

    func stopTunnel() async throws {
        let manager = try await updateTunnel(for: .disconnection)
        manager.session.stopTunnel()
    }

    var session: VPNSession {
        get async throws {
            try await loadedManager.session
        }
    }

    var status: NEVPNStatus {
        get async throws {
            try await session.status
        }
    }

    var connectedServer: LogicalServerInfo {
        get async throws {
            let response = try await loadedManager.session.send(WireguardProviderRequest.getCurrentLogicalAndServerId)
            guard case .ok(let data) = response, let data, let ids = String(data: data, encoding: .utf8) else {
                log.error("Error decoding getCurrentLogicalAndServerId response", category: .connection)
                throw TunnelManagerError.ipc(.getCurrentLogicalAndServerId, nil)
            }
            let id = ids.components(separatedBy: ";")
            guard id.count == 2 else {
                log.error("Unexpected number of elements in getCurrentLogicalAndServerId repsonse (expected 2, got \(id.count))", category: .connection)
                throw TunnelManagerError.ipc(.getCurrentLogicalAndServerId, nil)
            }

            return LogicalServerInfo(logicalID: id[0], serverID: id[1])
        }
    }

    var statusStream: AsyncStream<NEVPNStatus> {
        get async throws {
            let session = try await loadedManager.session
            let statusChangedNotifications = NotificationCenter.default
                .notifications(named: Notification.Name.NEVPNStatusDidChange, object: session)
                .map { _ in session.status }

            return AsyncStream(statusChangedNotifications)
        }
    }

    func removeManagers() async throws {
        try await managerFactory.removeAll()
    }
}

enum TunnelManagerError: Error {
    case ipc(WireguardProviderRequest, Error?)
}

@available(iOS 16, *)
extension DependencyValues {
    var tunnelManager: TunnelManager {
        get { self[TunnelManagerKey.self] }
        set { self[TunnelManagerKey.self] = newValue }
    }
}
