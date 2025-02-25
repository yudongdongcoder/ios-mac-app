//
//  Created on 29/7/24.
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

public enum ConnectionProtocol: String {
    case WireGuardUDP = "WireGuard"
    case WireGuardTCP = "WireGuard (TCP)"
    case Smart = "Smart"
    case Stealth = "Stealth"
#if os(macOS)
    case IKEv2 = "IKEv2"
#endif
}
