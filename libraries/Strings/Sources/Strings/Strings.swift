// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum Localizable {
  /// For buttons which have an action that connects to a server.
  public static var actionConnect: String { return Localizable.tr("Localizable", "_action_connect", fallback: "Connect") }
  /// For buttons which have an action that disconnects from a server.
  public static var actionDisconnect: String { return Localizable.tr("Localizable", "_action_disconnect", fallback: "Disconnect") }
  /// For buttons / navigation links which open a help menu or tooltip.
  public static var actionHelp: String { return Localizable.tr("Localizable", "_action_help", fallback: "Help") }
  /// Home screen: pin this connection in the recents view.
  public static var actionHomePin: String { return Localizable.tr("Localizable", "_action_home_pin", fallback: "Pin") }
  /// Home screen: unpin this connection from the recents view.
  public static var actionHomeUnpin: String { return Localizable.tr("Localizable", "_action_home_unpin", fallback: "Unpin") }
  /// For buttons which have an action that removes an item.
  public static var actionRemove: String { return Localizable.tr("Localizable", "_action_remove", fallback: "Remove") }
  /// Connection card in home tab, VoiceOver label for accessibility users. %@ is a country name.
  public static func connectionCardAccessibilityBrowsingFrom(_ p1: Any) -> String {
    return Localizable.tr("Localizable", "_connection_card_accessibility_browsing_from", String(describing: p1), fallback: "You are safely browsing from %@.")
  }
  /// Connection card in home tab, VoiceOver connection label for accessibility users. %@ is a country name.
  public static func connectionCardAccessibilityLastConnectedTo(_ p1: Any) -> String {
    return Localizable.tr("Localizable", "_connection_card_accessibility_last_connected_to", String(describing: p1), fallback: "You were last connected to %@.")
  }
  /// Connection card in home tab: "Last connected to... <country name>"
  public static var connectionCardLastConnectedTo: String { return Localizable.tr("Localizable", "_connection_card_last_connected_to", fallback: "Last connected to") }
  /// Connection card in home tab: "Safely browsing from... <country name>"
  public static var connectionCardSafelyBrowsingFrom: String { return Localizable.tr("Localizable", "_connection_card_safely_browsing_from", fallback: "Safely browsing from") }
  /// Countries tab in bottom menu
  public static var countriesTab: String { return Localizable.tr("Localizable", "_countries_tab", fallback: "Countries") }
  /// The section of pinned recent connections in the Home tab.
  public static var homeRecentsPinnedSection: String { return Localizable.tr("Localizable", "_home_recents_pinned_section", fallback: "Pinned") }
  /// The section of recent connections in the Home tab.
  public static var homeRecentsRecentSection: String { return Localizable.tr("Localizable", "_home_recents_recent_section", fallback: "Recent") }
  /// Home tab in bottom menu
  public static var homeTab: String { return Localizable.tr("Localizable", "_home_tab", fallback: "Home") }
  /// The hint that the screen reader will provide to voiceover users for the header in the home tab when the VPN is not connected to any server.
  public static var homeUnprotectedAccessibilityHint: String { return Localizable.tr("Localizable", "_home_unprotected_accessibility_hint", fallback: "The VPN is disconnected. Connect to a server to securely browse the internet.") }
  /// The accessibility label given for the header at the top of the home tab when the VPN is not connected to any server.
  public static func homeUnprotectedAccessibilityLabel(_ p1: Any) -> String {
    return Localizable.tr("Localizable", "_home_unprotected_accessibility_label", String(describing: p1), fallback: "You are browsing unprotected from %@.")
  }
  /// The header shown at the top of the application in the home tab when the VPN is not connected to any server.
  public static var homeUnprotectedHeader: String { return Localizable.tr("Localizable", "_home_unprotected_header", fallback: "You are unprotected") }
  /// Plural format key: "%#@VARIABLE@"
  public static func netshieldStatsAdsBlocked(_ p1: Int) -> String {
    return Localizable.tr("Localizable", "_netshield_stats_ads_blocked", p1, fallback: "Plural format key: \"%#@VARIABLE@\"")
  }
  /// Data
  /// saved
  public static var netshieldStatsDataSaved: String { return Localizable.tr("Localizable", "_netshield_stats_data_saved", fallback: "Data\nsaved") }
  /// Plural format key: "%#@VARIABLE@"
  public static func netshieldStatsTrackersStopped(_ p1: Int) -> String {
    return Localizable.tr("Localizable", "_netshield_stats_trackers_stopped", p1, fallback: "Plural format key: \"%#@VARIABLE@\"")
  }
  /// Secure core: connected to a country via another country. %@ is the country through which we are transiting to get to the final destination.
  public static func secureCoreViaCountry(_ p1: Any) -> String {
    return Localizable.tr("Localizable", "_secure_core_via_country", String(describing: p1), fallback: "via %@")
  }
  /// Settings tab in bottom menu
  public static var settingsTab: String { return Localizable.tr("Localizable", "_settings_tab", fallback: "Settings") }
  /// Connection status title when user is connected to a VPN
  public static var connectionStatusProtected: String { return Localizable.tr("Localizable", "connection_status_protected", fallback: "Protected") }
  /// Connection status title when user is initiating connection to a VPN
  public static var connectionStatusProtecting: String { return Localizable.tr("Localizable", "connection_status_protecting", fallback: "Protecting your digital identity") }
  /// Connection status title when user is not connected to a VPN
  public static var connectionStatusUnprotected: String { return Localizable.tr("Localizable", "connection_status_unprotected", fallback: "You are unprotected") }
  /// The hint that appears on mac when user hovers with a mouse over the value of netshield stats - advertisements blocked
  public static var netshieldStatsHintAds: String { return Localizable.tr("Localizable", "netshield_stats_hint_ads", fallback: "Advertisement websites use cookies and trackers to target you.") }
  /// The hint that appears on mac when user hovers with a mouse over the value of netshield stats - data saved
  public static var netshieldStatsHintData: String { return Localizable.tr("Localizable", "netshield_stats_hint_data", fallback: "Estimated size of ads, trackers, and malware that NetShield has blocked.") }
  /// The hint that appears on mac when user hovers with a mouse over the value of netshield stats - trackers stopped
  public static var netshieldStatsHintTrackers: String { return Localizable.tr("Localizable", "netshield_stats_hint_trackers", fallback: "Trackers are third-party websites that collect, store, and sell information about your web activity.") }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Localizable {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = localizeStringAndFallbackToEn(key, table, value)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
