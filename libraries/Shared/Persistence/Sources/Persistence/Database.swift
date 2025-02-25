//
//  Created on 30/11/2023.
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

import Foundation

import Dependencies
import GRDB

/// > SQLite documentation:
/// Every :memory: database is distinct from every other. So, opening two database connections each with the filename
/// ":memory:" will create two independent in-memory databases.
/// [In-Memory Databases](https://www.sqlite.org/inmemorydb.html)
public enum DatabaseType: CustomStringConvertible {

    /// Global in-memory database shared across all `DatabaseWriter` instances initialised with this type
    case inMemory

    /// Isolated in-memory database instance (optionally initialised from a physical file)
    case ephemeral(filePath: String?)

    /// Database initialised from, and persisted to, a physical file.
    ///
    /// According to apple guidelines (specifically for iOS, but the same is also applicable for MacOS), the appropriate
    /// location for such a database is the Application Support directory:
    ///
    /// > iOS Storage Best Practices:
    /// The Application Support directory is a good place to store files that might be in your Documents directory but
    /// that shouldn't be seen by users. For example, a database that your app needs but that the user would never open
    /// manually.
    /// [iOS Storage Best Practices](https://developer.apple.com/videos/play/tech-talks/204?time=225)
    case physical(filePath: String)

    /// Convenience overload of `ephemeral(filePath: String?)`. New in-memory database instance, not based off an
    /// existing file
    public static var ephemeral: Self { .ephemeral(filePath: nil) }

    public var description: String {
        switch self {
        case .inMemory:
            return "inMemory"
        case .ephemeral:
            return "ephemeral"
        case .physical(let filePath):
            return "physical(\(filePath.redactingUsername)"
        }
    }
}

extension DatabaseWriter {

    private static func createQueue(databaseType: DatabaseType, configuration: Configuration) throws -> DatabaseQueue {
        switch databaseType {
        case .inMemory:
            return try DatabaseQueue(named: "global", configuration: configuration)

        case .ephemeral(let path):
            if let path {
                return try DatabaseQueue.inMemoryCopy(fromPath: path, configuration: configuration)
            }
            return try DatabaseQueue(configuration: configuration)

        case .physical(let path):
            let writer = try DatabaseQueue(path: path, configuration: configuration)

            // Check if database contains unknown migrations from the future
            if try Migrator.default.containsUnknownMigrations(writer) {
                // These unknown migrations *could* be compatible with this build's logic. But let's nuke the database
                // in case they aren't, to avoid defaulting to showing an empty server list and failing to connect to
                // any server. This should never happen unless the app is intentionally downgraded by the user.
                try writer.close()
                try FileManager.default.removeItem(atPath: path)

                // Don't continue in DEBUG builds. This failure should be visible:
                // e.g. maybe we forgot to provide a reverse migration when rolling back?
                // Since we've nuked the potentially incompatible migration, we should be okay the next time we launch.

                // If you've triggered this assertion after downgrading your installation/checking out an earlier,
                // commit - it's safe to ignore. In all other scenarios this is a *SERIOUS* error. Refer to the
                // migrations chapter of this package's README.md for more information about how to proceed.
                assertionFailure("Uknown migration(s) detected in database!")

                // Create fresh database
                return try DatabaseQueue(path: path, configuration: configuration)
            }

            return writer
        }
    }

    public static func from(databaseConfiguration: DatabaseConfiguration) -> DatabaseQueue {
        let databaseType = databaseConfiguration.databaseType

        log.info("Preparing database queue", category: .persistence, metadata: ["type": "\(databaseType)"])

        var config = Configuration() // GRDB config, not to be confused with our `DatabaseConfiguration`

        config.prepareDatabase { db in
            db.add(function: bitwiseOr)
            db.add(function: bitwiseAnd)
            db.add(function: localizedCountryName.createFunctionForRegistration())
        }

        let queue = try! createQueue(databaseType: databaseType, configuration: config)

        let schemaVersion = databaseConfiguration.schemaVersion
        try! Migrator.default.migrate(queue, upTo: schemaVersion)

        return queue
    }
}
