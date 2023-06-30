//
//  Created on 29/06/2023.
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

import SwiftUI
import AppKit

struct LoginViewControllerRepresentable: NSViewControllerRepresentable {

    typealias NSViewControllerType = LoginViewController

    let loginViewModel: LoginViewModel

    func makeNSViewController(context: Context) -> LoginViewController {
        return LoginViewController(viewModel: loginViewModel)
    }

    func updateNSViewController(_ nsViewController: LoginViewController, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject {

    }
}

//struct LoginViewControllerRepresentable_Previews : PreviewProvider {
//    static var previews: some View {
//        LoginViewControllerRepresentable()
//    }
//}
