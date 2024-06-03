//
//  Created on 03/06/2024.
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
import Theme

struct CountryListItemView: View {
    let item: HomeListItem
    let isFocused: Bool
    @State var duration = 0.1

    private let normalScale = CGSize(width: 1, height: 1)
    private let focusedScale = CGSize(width: 1.3, height: 1.3)

    var body: some View {
        VStack(spacing: 0) {
            SimpleFlagView(regionCode: item.code, flagSize: .tvListSize)
                .hoverEffect(.highlight)
            Spacer()
                .frame(height: 34)
            VStack(spacing: 0) {
                Text(item.name)
                    .font(.body)
                Spacer()
                    .frame(height: 16)
                HStack(spacing: .themeSpacing12) {
                    Text("Connected")
                        .font(.caption)
                        .foregroundStyle(Asset.vpnGreen.swiftUIColor)
                    ConnectedCircleView()
                }
                .opacity(item.isConnected ? 1 : 0)
            }
            // This scaleEffect aims to mimic ".hoverEffect(.highlight)"
            .scaleEffect(isFocused ? focusedScale : normalScale)
            .animation(.easeOut(duration: duration), value: isFocused)
            .onChange(of: isFocused) { _, newValue in
                duration = newValue ? 0.4 : 0.1
            }
        }
    }
}
