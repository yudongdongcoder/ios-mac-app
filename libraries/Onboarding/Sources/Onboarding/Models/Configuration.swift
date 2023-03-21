//
//  Created on 04.01.2022.
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
import SwiftUI
import Theme

public struct Colors {
    public let background: UIColor
    public let buttonTitle: UIColor
    public let text: UIColor
    public let brand: UIColor
    public let weakText: UIColor
    public var textAccent: UIColor
    public let weakInteraction: UIColor
    let activeBrandButton: UIColor
    public let secondaryBackground: UIColor
    let textInverted: UIColor
    let notification: UIColor

    public init() {
        self.background = ColorPaletteiOS.instance.BackgroundNorm
        self.buttonTitle = ColorPaletteiOS.instance.White
        self.text = ColorPaletteiOS.instance.TextNorm
        self.textAccent = ColorPaletteiOS.instance.TextAccent
        self.brand = ColorPaletteiOS.instance.BrandNorm
        self.weakText = ColorPaletteiOS.instance.TextWeak
        self.activeBrandButton = ColorPaletteiOS.instance.BrandLighten20
        self.secondaryBackground = ColorPaletteiOS.instance.BackgroundSecondary
        self.textInverted = ColorPaletteiOS.instance.TextInverted
        self.notification = ColorPaletteiOS.instance.NotificationNorm
        self.weakInteraction = ColorPaletteiOS.instance.InteractionWeak
    }
}

public struct Constants {
    public let numberOfDevices: Int
    public let numberOfServers: Int
    let numberOfFreeServers: Int
    let numberOfFreeCountries: Int
    public let numberOfCountries: Int

    public init(numberOfDevices: Int, numberOfServers: Int, numberOfFreeServers: Int, numberOfFreeCountries: Int, numberOfCountries: Int) {
        self.numberOfDevices = numberOfDevices
        self.numberOfServers = numberOfServers
        self.numberOfFreeServers = numberOfFreeServers
        self.numberOfFreeCountries = numberOfFreeCountries
        self.numberOfCountries = numberOfCountries
    }
}

public struct Configuration {
    let constants: Constants
    let telemetryEnabled: Bool

    public init(constants: Constants,
                telemetryEnabled: Bool) {
        self.constants = constants
        self.telemetryEnabled = telemetryEnabled
    }
}

extension UIColor {
    var suColor: Color { Color(self) }
}
