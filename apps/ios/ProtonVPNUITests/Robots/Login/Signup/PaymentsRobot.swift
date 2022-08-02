//
//  Created on 2021-12-21.
//
//  Copyright (c) 2021 Proton AG
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

import pmtest
import ProtonCore_TestingToolkit

fileprivate let titleId = "PaymentsUIViewController.tableHeaderLabel"
fileprivate let freePlanTitle = "Free.planNameLabel"

class PaymentsRobot: CoreElements {
    
    let corePaymentUIRobot = ProtonCore_TestingToolkit.PaymentsUIRobot()
    
    public let verify = Verify()
    
    class Verify: CoreElements {
        
        @discardableResult
        func subscriptionScreenIsShown() -> PaymentsRobot {
            staticText(titleId).wait(time: 10).checkExists()
            staticText(freePlanTitle).wait(time: 10).checkExists()
            return PaymentsRobot()
        }
    }
}
