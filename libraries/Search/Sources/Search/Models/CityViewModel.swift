//
//  Created on 15.03.2022.
//
//  Copyright (c) 2022 Proton AG
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
import UIKit

public protocol CityViewModel: ConnectViewModel {
    var cityName: String { get }
    var translatedCityName: String? { get }
    var countryName: String { get }
    var countryFlag: UIImage? { get }
    var isRedesign: Bool { get }

    var connectionChanged: (() -> Void)? { get set }
}

extension CityViewModel {
    var displayCityName: String {
        return translatedCityName ?? cityName
    }
}
