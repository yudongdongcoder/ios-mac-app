//
//  AccountPlan.swift
//  vpncore - Created on 26.06.19.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of vpncore.
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
//  along with vpncore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public enum AccountPlan: String {
    
    case free = "free"
    case basic = "vpnbasic"
    case plus = "vpnplus"
    case visionary = "visionary"
    case trial = "trial"
    
    public var paid: Bool {
        switch self {
        case .free, .trial:
            return false
        default:
            return true
        }
    }
    
    public var description: String {
        switch self {
        case .free:
            return "ProtonVPN Free"
        case .basic:
            return "ProtonVPN Basic"
        case .plus:
            return "ProtonVPN Plus"
        case .visionary:
            return "Proton Visionary"
        case .trial:
            return "ProtonVPN Plus Trial"
        }
    }
    
    public var storeKitProductId: String? {
        switch self {
        case .free, .visionary, .trial:
            return nil
        case .basic:
            return "ios_vpnbasic_12_usd_non_renewing"
        case .plus:
            return "ios_vpnplus_12_usd_non_renewing"
        }
    }
    
    public init(planName: String) {
        if planName == "vpnbasic" {
            self = .basic
        } else if planName == "vpnplus" {
            self = .plus
        } else if planName == "visionary" {
            self = .visionary
        } else if planName == "trial" {
            self = .trial
        } else {
            self = .free
        }
    }
    
    // MARK: - UI info
    public init?(storeKitProductId: String) {
        switch storeKitProductId {
        case AccountPlan.basic.storeKitProductId:
            self = .basic
        case AccountPlan.plus.storeKitProductId:
            self = .plus
        default:
            return nil
        }
    }
    
    public var name: String {
        switch self {
        case .basic:
            return LocalizedString.tierBasic
        case .plus:
            return LocalizedString.tierPlus
        case .visionary:
            return LocalizedString.tierVisionary
        default:
            return LocalizedString.tierFree
        }
    }
    
    public var displayName: String {
        let protonVPN = "ProtonVPN %@"
        switch self {
        case .free, .trial:
            return String(format: protonVPN, "FREE")
        case .basic:
            return String(format: protonVPN, "BASIC")
        case .plus:
            return String(format: protonVPN, "PLUS")
        case .visionary:
            return String(format: protonVPN, "VISIONARY")
        }
    }
    
    // FUTUREFIXME: should get this from api
    public var yearlyCost: Int {
        switch self {
        case .free, .trial:
            return 0
        case .basic:
            return 4800
        case .plus:
            return 9600
        case .visionary:
            return 28800
        }
    }
    
    public var callToAction: String {
        switch self {
        case .free, .trial:
            return LocalizedString.getPlan("Free")
        case .basic:
            return LocalizedString.getPlan("Basic")
        case .plus:
            return LocalizedString.getPlan("Plus")
        case .visionary:
            return LocalizedString.getPlan("Visionary")
        }
    }
    
    public var devicesCount: Int {
        switch self {
        case .plus:
            return 10
        case .basic:
            return 2
        default:
            return 1
        }
    }

    public var countriesCount: Int {
        switch self {
        case .plus:
            return 61
        case .basic:
            return 40
        default:
            return 3
        }
    }

    public var serversCount: Int {
        switch self {
        case .plus:
            return 1600
        case .basic:
            return 400
        default:
            return 24
        }
    }
    
    public var speed: String {
        switch self {
        case .free:
            return LocalizedString.medium
        case .basic:
            return LocalizedString.high
        case .plus, .visionary, .trial:
            return LocalizedString.fastest
        }
    }
    
    public var speedDescription: String {
        switch self {
        case .free:
            return LocalizedString.planSpeedMedium
        case .basic:
            return LocalizedString.planSpeedHigh
        case .plus, .visionary, .trial:
            return LocalizedString.planSpeedFastest
        }
    }
    
    public var features: String {
        switch self {
        case .free, .basic:
            return ""
        case .plus, .visionary, .trial:
            return LocalizedString.plusPlanFeatures
        }
    }
    
    public var isMostPopular: Bool {
        switch self {
        case .plus:
            return true
        default:
            return false
        }
    }
    
    public var hasAdvancedFeatures: Bool {
        switch self {
        case .plus:
            return true
        default:
            return false
        }
    }
    
    // MARK: - NSCoding
    private struct CoderKey {
        static let accountPlan = "accountPlan"
    }
    
    public init(coder aDecoder: NSCoder) {
        self.init(planName: aDecoder.decodeObject(forKey: CoderKey.accountPlan) as! String)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(rawValue, forKey: CoderKey.accountPlan)
    }
}
