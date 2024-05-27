//
//  Created on 23/05/2024.
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

import ComposableArchitecture
import Foundation
import CommonNetworking
import Domain
import Localization

struct HomeListSection: Equatable {
    let name: String
    let items: [HomeListItem]
}

extension HomeListSection: Identifiable {
    var id: String { name }
}

struct HomeListItem: Identifiable, Equatable {
    var id: String = UUID().uuidString

    let code: String
    let name: String
    let isConnected: Bool
}

@Reducer
struct CountryListFeature {

    @ObservableState
    struct State: Equatable {
        var sections: [HomeListSection] = []
    }

    enum Action {
        case loadLogicals
        case selectItem(HomeListItem)
        case updateList
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadLogicals:
                return .run(operation: { (send) in
                    @Dependency(\.logicalsClient) var client
                    let logicalsResponse = try await client.fetchLogicals()

                    @Dependency(\.serverRepository) var repository
                    repository.upsert(servers: logicalsResponse.logicalServers.map { $0.persistanceServer })

                    await send(.updateList) // Refresh UI from DB

                }, catch: { error, action in
                    print("loadLogicals error: \(error)")
                    // TODO: error handling
                })
                
            case .updateList:
                @Dependency(\.serverRepository) var repository
                let allCountries = repository
                    .getGroups(filteredBy: [.isNotUnderMaintenance])
                    .compactMap { $0.item }

                state.sections = [
                    HomeListSection(
                        name: "Recommended",
                        items: [fastest] // TODO: add recommended
                    ),
                    HomeListSection(
                        name: "All countries",
                        items: [fastest] + allCountries
                    ),
                ]
                return .none

            case .selectItem(let item):
                print(item)
                return .none
            }
        }
    }

    private var fastest: HomeListItem {
        HomeListItem(
            code: "Fastest",
            name: "Fastest",
            isConnected: false // TODO:
        )
    }
}

extension LogicalDTO {
    var persistanceServer: VPNServer {
        VPNServer(
            logical: Logical(
                id: id,
                name: name,
                domain: domain,
                load: load,
                entryCountryCode: entryCountry,
                exitCountryCode: exitCountry,
                tier: tier,
                score: score,
                status: status,
                feature: features,
                city: city,
                hostCountry: hostCountry,
                translatedCity: translatedCity,
                latitude: location.lat,
                longitude: location.long,
                gatewayName: gatewayName
            ),
            endpoints: servers.map {
                ServerEndpoint(
                    id: $0.id,
                    exitIp: $0.exitIp,
                    domain: $0.domain,
                    status: $0.status,
                    protocolEntries: nil // TODO: pass actual value, when we'll have it
                )
            }
        )
    }
}

extension ServerGroupInfo {
    var item: HomeListItem? {
        switch kind {
        case .country(let code):
            return HomeListItem(
            code: code,
            name: LocalizationUtility.default.countryName(forCode: code) ?? "",
            isConnected: false // TODO:
        )
        default:
            return nil
        }
    }
}
