//
//  Created on 07/07/2023.
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

import Foundation
import Dependencies



extension DependencyValues {
    public var disconnectVPN: @Sendable () -> Void {
    get { self[DisconnectVPNKey.self] }
    set { self[DisconnectVPNKey.self] = newValue }
  }
}

public enum DisconnectVPNKey: DependencyKey {
    public static let liveValue: @Sendable () -> Void = {
        // After Accounts SPM migration, real implementation should live here
        assertionFailure("Use real implementation from VPNCore")
    }
}
