//
//  Created on 04/06/2024.
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

import SwiftUI
import ComposableArchitecture
import ProtonCoreUIFoundations
import Localization
import Domain
import Connection
import Theme

struct ProtectionStatusView: View {

    @Bindable var store: StoreOf<ProtectionStatusFeature>

    struct Model {
        var icon: Image?
        var title: LocalizedStringKey
        var foregroundColor: Color
        var buttonTitle: LocalizedStringKey

        init(connectionState: Connection.ConnectionState?) {
            switch connectionState ?? .disconnected(nil) {
            case .connected:
                icon = IconProvider.lockFilled
                title = "Protected"
                foregroundColor = Asset.vpnGreen.swiftUIColor
                buttonTitle = "Disconnect"
            case .connecting:
                icon = nil
                title = "Connecting"
                foregroundColor = Color(.text)
                buttonTitle = "Cancel"
            case .disconnected:
                icon = IconProvider.lockOpenFilled
                title = "Unprotected"
                foregroundColor = Color(.text, .danger)
                buttonTitle = "Quick Connect"
            case .disconnecting:
                icon = nil
                title = "Disconnecting"
                foregroundColor = Color(.text)
                buttonTitle = "Quick Connect"
            }
        }
    }

    var body: some View {
        view(model: .init(connectionState: store.connectionState ?? .disconnected(nil)))
    }

    private func view(model: Model) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: .themeSpacing32) {
                protectionTitle(model: model)
                location
                button(model: model)
            }
            Spacer()
                .frame(maxWidth: .infinity)
        }
        .onAppear { store.send(.onAppear) }
        .focusSection()
    }

    private func protectionTitle(model: Model) -> some View {
        HStack(spacing: .themeSpacing24) {
            protectionIcon(model: model)
            Text(model.title)
                .font(.title3)
        }
        .foregroundStyle(model.foregroundColor)
    }

    @ViewBuilder
    private func protectionIcon(model: Model) -> some View {
        if let icon = model.icon {
            icon.resizable()
                .frame(.square(56))
        } else {
            ProgressView()
        }
    }
    
    @ViewBuilder
    private var locationText: Text? {
        if let location = displayedLocation {
            Text(verbatim: LocalizationUtility.default.countryName(forCode: location.country) ?? "")
            +
            Text(verbatim: " • \(location.ip)")
                .foregroundStyle(Color(.text, .weak))
        }
    }

    private var displayedLocation: UserLocation? {
        let country: String?
        let ip: String?

        switch store.connectionState ?? .disconnected(nil) {
        case .connected(let server, let connectionDetails):
            country = server.logical.exitCountryCode
            ip = connectionDetails.map { String(describing: $0.exitIp) } ?? server.endpoint.exitIp
        default:
            country = store.userLocation?.country
            ip = store.userLocation?.ip
        }
        guard let country, let ip else { return nil }
        return .init(ip: ip, country: country, isp: "")
    }

    private var location: some View {
        locationText
            .font(.body)
            .padding(.vertical, .themeSpacing24)
            .padding(.horizontal, 32)
            .background(Color(.materialRegular))
            .clipRectangle(cornerRadius: .radius16)
    }

    private func button(model: Model) -> some View {
        Button {
            store.send(.userTappedButton)
        } label: {
            Text(model.buttonTitle)
                .font(.body)
                .bold()
        }
        .buttonStyle(ConnectButtonStyle())
    }
}

private struct ConnectButtonStyle: ButtonStyle {

    @Environment(\.isFocused) var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, .themeSpacing24)
            .padding(.horizontal, .themeSpacing32)
            .background(isFocused ? Color(.background, .selected) : Color(.background, .weak))
            .foregroundStyle(isFocused ? Color(.text, .inverted) : Color(.text))
            .cornerRadius(.themeRadius16)
            .hoverEffect(.highlight)
    }
}
