//
//  Created on 7/26/24.
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

import Foundation
import GRDB

extension SchemaVersion {

    public static let v2: SchemaVersion = {
        let migrationBlock: MigrationBlock = { db in
            try db.create(table: "databaseMetadata") { t in
                t.column("key", .text).notNull().primaryKey(onConflict: .replace)
                t.column("value", .text).notNull()
            }
        }

        return SchemaVersion(identifier: "database_metadata", migrationBlock: migrationBlock)
    }()
}
