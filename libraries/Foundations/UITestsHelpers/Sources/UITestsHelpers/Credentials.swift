//
//  Credentials.swift
//  ProtonVPN - Created on 27.06.19.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonVPN.
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
//

import Foundation

public struct Credentials: Decodable {
    public let username: String
    public let password: String
    public let plan: String
    
    public init(username: String, password: String, plan: String) {
        self.username = username
        self.password = password
        self.plan = plan
    }
    
    public static func loadFrom(plistUrl: URL) -> [Credentials] {
        let data = try! Data(contentsOf: plistUrl)
        let decoder = PropertyListDecoder()
        return try! decoder.decode([Credentials].self, from: data)
    }
}

extension Array<Credentials> {
    subscript<K: RawRepresentable<Int>>(_ key: K) -> Element {
        self[key.rawValue]
    }
}
