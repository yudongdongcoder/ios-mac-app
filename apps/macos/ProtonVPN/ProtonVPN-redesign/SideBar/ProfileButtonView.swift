//
//  Created on 15/05/2023.
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

#if REDESIGN

import SwiftUI
import Theme
import ProtonCoreUIFoundations

struct ProfileButtonView: View {
    var body: some View {
        IconProvider.userCircle
            .resizable()
            .frame(.square(.themeSpacing16))
            .tint(Color(.text))
            .padding(.themeSpacing24)
    }
}

#endif
