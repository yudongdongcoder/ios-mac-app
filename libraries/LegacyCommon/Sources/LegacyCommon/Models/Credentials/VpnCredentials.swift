//
//  VpnCredentials.swift
//  vpncore - Created on 26.06.19.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of LegacyCommon.
//
//  vpncore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  vpncore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with LegacyCommon.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import VPNShared
import Strings
import ProtonCoreNetworking

public class VpnCredentials: NSObject, NSSecureCoding, Codable {

    public static var supportsSecureCoding: Bool = true

    public let status: Int
    public let planTitle: String
    public let planName: String
    public let maxConnect: Int
    public let maxTier: Int
    public let services: Int?
    public let groupId: String
    public let name: String
    public let password: String
    public let delinquent: Int
    public let credit: Int
    public let currency: String
    public let hasPaymentMethod: Bool
    public let subscribed: Int?
    public let businessEvents: Bool

    override public var description: String {
        "Status: \(status)\n" +
        "Plan title: \(planTitle)\n" +
        "Plan name: \(planName)\n" +
        "Max connect: \(maxConnect)\n" +
        "Max tier: \(maxTier)\n" +
        "Services: \(services ?? -1)\n" +
        "Group ID: \(groupId)\n" +
        "Name: \(name)\n" +
        "Password: \(password)\n" +
        "Delinquent: \(delinquent)\n" +
        "Credit: \(credit) (in \(currency))" +
        "Has Payment Method: \(hasPaymentMethod)\n" +
        "Subscribed: \(String(describing: subscribed))" +
        "BusinessEvents: \(businessEvents)"
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(Int.self, forKey: .status)
        self.planTitle = (try? container.decodeIfPresent(String.self, forKey: .planTitle)) ?? Localizable.freeTierPlanTitle
        self.planName = (try? container.decodeIfPresent(String.self, forKey: .planName)) ?? "free"
        self.maxConnect = try container.decode(Int.self, forKey: .maxConnect)
        self.maxTier = try container.decode(Int.self, forKey: .maxTier)
        self.services = try container.decode(Int.self, forKey: .services)
        self.groupId = try container.decode(String.self, forKey: .groupId)
        self.name = try container.decode(String.self, forKey: .name)
        self.password = try container.decode(String.self, forKey: .password)
        self.delinquent = try container.decode(Int.self, forKey: .delinquent)
        self.credit = try container.decode(Int.self, forKey: .credit)
        self.currency = try container.decode(String.self, forKey: .currency)
        self.hasPaymentMethod = try container.decode(Bool.self, forKey: .hasPaymentMethod)
        self.subscribed = try container.decodeIfPresent(Int.self, forKey: .subscribed)
        self.businessEvents = try container.decode(Bool.self, forKey: .businessEvents)
    }

    public init(
        status: Int,
        planTitle: String,
        maxConnect: Int,
        maxTier: Int,
        services: Int?,
        groupId: String,
        name: String,
        password: String,
        delinquent: Int,
        credit: Int,
        currency: String,
        hasPaymentMethod: Bool,
        planName: String,
        subscribed: Int?,
        businessEvents: Bool
    ) {
        self.status = status
        self.planTitle = planTitle
        self.maxConnect = maxConnect
        self.maxTier = maxTier
        self.services = services
        self.groupId = groupId
        self.name = name
        self.password = password
        self.delinquent = delinquent
        self.credit = credit
        self.currency = currency
        self.hasPaymentMethod = hasPaymentMethod
        self.planName = planName // Saving original string we got from API, because we need to know if it was null
        self.subscribed = subscribed
        self.businessEvents = businessEvents
        super.init()
    }
    
    init(dic: JSONDictionary) throws {
        let vpnDic = try dic.jsonDictionaryOrThrow(key: "VPN")

        planTitle = vpnDic.string("PlanTitle") ?? Localizable.freeTierPlanTitle
        planName = vpnDic.string("PlanName") ?? "free"
        status = try vpnDic.intOrThrow(key: "Status")
        maxConnect = try vpnDic.intOrThrow(key: "MaxConnect")
        maxTier = vpnDic.int(key: "MaxTier") ?? .freeTier
        services = try dic.intOrThrow(key: "Services")
        groupId = try vpnDic.stringOrThrow(key: "GroupID")
        name = try vpnDic.stringOrThrow(key: "Name")
        password = try vpnDic.stringOrThrow(key: "Password")
        delinquent = try dic.intOrThrow(key: "Delinquent")
        credit = try dic.intOrThrow(key: "Credit")
        currency = try dic.stringOrThrow(key: "Currency")
        hasPaymentMethod = try dic.boolOrThrow(key: "HasPaymentMethod")
        subscribed = dic.int(key: "Subscribed")
        businessEvents = vpnDic.bool(key: "BusinessEvents", or: false)
        super.init()
    }

    /// Used for testing purposes.
    var asDict: JSONDictionary {
        ([
            "VPN": [
                "PlanName": planName,
                "PlanTitle": planTitle,
                "Status": status,
                "MaxConnect": maxConnect,
                "MaxTier": maxTier,
                "GroupID": groupId,
                "Name": name,
                "Password": password,
                "BusinessEvents": businessEvents,
            ] as [String: Any],
            "Services": services ?? -1,
            "Delinquent": delinquent,
            "Credit": credit,
            "Currency": currency,
            "HasPaymentMethod": hasPaymentMethod,
            "Subscribed": subscribed ?? 0,
        ] as [String: Any])
        .mapValues({ $0 as AnyObject })
    }
    
    // MARK: - NSCoding
    private struct CoderKey {
        static let status = "status"
        static let planTitle = "planTitle"
        static let planName = "planName"
        static let maxConnect = "maxConnect"
        static let maxTier = "maxTier"
        static let services = "services"
        static let groupId = "groupId"
        static let name = "name"
        static let password = "password"
        static let delinquent = "delinquent"
        static let credit = "credit"
        static let currency = "currency"
        static let hasPaymentMethod = "hasPaymentMethod"
        static let accountPlan = "accountPlan"
        static let subscribed = "subscribed"
        static let businessEvents = "businessEvents"
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let groupId = aDecoder.decodeObject(forKey: CoderKey.groupId) as? String,
              let name = aDecoder.decodeObject(forKey: CoderKey.name) as? String,
              let password = aDecoder.decodeObject(forKey: CoderKey.password) as? String,
              let subscribed = aDecoder.decodeObject(forKey: CoderKey.subscribed) as? Int else {
            return nil
        }
        self.init(
            status: aDecoder.decodeInteger(forKey: CoderKey.status),
            planTitle: Localizable.freeTierPlanTitle,
            maxConnect: aDecoder.decodeInteger(forKey: CoderKey.maxConnect),
            maxTier: aDecoder.decodeInteger(forKey: CoderKey.maxTier),
            services: aDecoder.decodeInteger(forKey: CoderKey.services),
            groupId: groupId,
            name: name,
            password: password,
            delinquent: aDecoder.decodeInteger(forKey: CoderKey.delinquent),
            credit: aDecoder.decodeInteger(forKey: CoderKey.credit),
            currency: aDecoder.decodeObject(forKey: CoderKey.currency) as? String ?? "",
            hasPaymentMethod: aDecoder.decodeBool(forKey: CoderKey.hasPaymentMethod),
            planName: aDecoder.decodeObject(forKey: CoderKey.accountPlan) as? String ?? "free",
            subscribed: subscribed,
            businessEvents: aDecoder.decodeBool(forKey: CoderKey.businessEvents)
        )
    }

    public func encode(with aCoder: NSCoder) {
        log.assertionFailure("We migrated away from NSCoding, this method shouldn't be used anymore")
    }
}

extension VpnCredentials {
    public var isDelinquent: Bool {
        return delinquent > 2
    }
}

/// Contains everything that VpnCredentials has, minus the username, password, group ID,
/// and expiration date/time.
/// This lets us avoid querying the keychain unnecessarily, since every query results in a synchronous
/// roundtrip to securityd.
public struct CachedVpnCredentials {
    public let status: Int
    public let planName: String
    public let planTitle: String
    public let maxConnect: Int
    public let maxTier: Int
    public let services: Int?
    public let delinquent: Int
    public let credit: Int
    public let currency: String
    public let hasPaymentMethod: Bool
    public let subscribed: Int?
    public let businessEvents: Bool

    public var canUsePromoCode: Bool {
        return !isDelinquent && !hasPaymentMethod && credit == 0 && subscribed == 0
    }
}

extension CachedVpnCredentials {
    init(credentials: VpnCredentials) {
        self.init(
            status: credentials.status,
            planName: credentials.planName, 
            planTitle: credentials.planTitle,
            maxConnect: credentials.maxConnect,
            maxTier: credentials.maxTier,
            services: credentials.services,
            delinquent: credentials.delinquent,
            credit: credentials.credit,
            currency: credentials.currency,
            hasPaymentMethod: credentials.hasPaymentMethod,
            subscribed: credentials.subscribed, 
            businessEvents: credentials.businessEvents
        )
    }
}

// MARK: - Checks performed on CachedVpnCredentials
extension CachedVpnCredentials {
    public var isDelinquent: Bool {
        return delinquent > 2
    }
}
