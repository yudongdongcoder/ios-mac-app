//
//  Created on 10/07/2023.
//
//  Copyright (c) 2023 Proton AG
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

import Domain
import Strings

import VPNAppCore

public struct ConnectionCardModel {

    public init() {

    }

    public func accessibilityText(for vpnConnectionStatus: VPNConnectionStatus,
                           countryName: String) -> String {
        switch vpnConnectionStatus {
        case .disconnected, .disconnecting:
            return Localizable.connectionCardAccessibilityLastConnectedTo(countryName)
        case .connected:
            return Localizable.connectionCardAccessibilityBrowsingFrom(countryName)
        case .connecting, .loadingConnectionInfo:
            return Localizable.connectionCardAccessibilityConnectingTo(countryName)
        }
    }

    public func buttonText(for vpnConnectionStatus: VPNConnectionStatus) -> String {
        switch vpnConnectionStatus {
        case .disconnected:
            return Localizable.actionConnect
        case .connected:
            return Localizable.actionDisconnect
        case .connecting, .loadingConnectionInfo:
            return Localizable.connectionCardActionCancel
        case .disconnecting:
            return Localizable.connectionCardActionCancel // ? not sure
        }
    }

}
