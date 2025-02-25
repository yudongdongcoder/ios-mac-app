//
//  Created on 12/06/2024.
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

import Persistence
import Domain

extension ServerRepository {
    public static func empty() -> Self {
        .init(serverCount: { 0 },
              server: { _, _ in nil },
              groups: { _, _ in [] })
    }
    public static func notEmpty() -> Self {
        .init(serverCount: { 1 },
              server: { _, _ in .mock },
              groups: { _, _ in [] })
    }

    public static func somePlusRecommendedCountries() -> Self {
        .init(serverCount: { 0 },
              server: { _, _ in nil },
              groups: { _, _ in .recommendedCountries + .someCountries })
    }
    
    public static func emptyWithUpsert() -> Self {
        .init(serverCount: { 0 }, 
              upsertServers: { _ in },
              groups: { _, _ in [] })
    }
}

extension VPNServer {
    static var mock: Self {
        .init(logical: .mock, endpoints: [.mock])
    }
}

extension [ServerGroupInfo] {
    static var recommendedCountries: Self {
        ["US", "UK", "CA", "FR", "DE"]
            .map { .country(code: $0) }
    }
    static var someCountries: Self {
        ["PL", "AR", "RO", "LT", "CZ"]
            .map { .country(code: $0) }
    }
}

extension ServerGroupInfo {
    static func country(code: String) -> Self {
        .init(kind: .country(code: code),
              featureIntersection: .zero,
              featureUnion: .zero,
              minTier: 0,
              maxTier: 0,
              serverCount: 5,
              cityCount: 0,
              latitude: 0,
              longitude: 0,
              supportsSmartRouting: false,
              isUnderMaintenance: false,
              protocolSupport: .all)
    }
}

extension ServerEndpoint {
    static var mock: Self {
        .init(
            id: "some id",
            entryIp: "1.2.3.4",
            exitIp: "4.3.2.1",
            domain: "domain",
            status: 1,
            label: nil,
            x25519PublicKey: nil,
            protocolEntries: nil
        )
    }
}

extension Logical {
    static var mock: Self {
        .init(
            id: "",
            name: "",
            domain: "",
            load: 0,
            entryCountryCode: "",
            exitCountryCode: "",
            tier: 0,
            score: 0,
            status: 0,
            feature: [],
            city: nil,
            hostCountry: nil,
            translatedCity: nil,
            latitude: 0,
            longitude: 0,
            gatewayName: nil
        )
    }
}
