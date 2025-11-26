//
//  UserPreferenceKeys.swift
//  Klick
//
//  Created by Manase on 26/11/2025.
//
import Foundation

enum UserPreferenceKeys: String, CaseIterable {
    case onboardingCompleted
    case currencyPicked
    case whatsNew
    
    case balanceAllocationIntroCompleted
    case avatarIntroCompleted
    case walletIntroCompleted
    
    /// Smart receipt camera
    case smartReceiptInfoShown
    
    /// Premium
    case eligibleForPremium
    
    /// Notifications and Reminders
    case recurringScheduleExpenseAlert
    case budgetLowAlert
    case savingLowAlert
    case hiveCycleCompletionAlert
    case hiveCycleCompletionReminderAlert
    case notificationPrimeSet
    
    func save(_ value: Any) {
        UserDefaults.standard.set(value, forKey: rawValue)
//        SVLogger.main.log(message: "User preference saved", info: "Key: \(rawValue), Value: \(value)", logLevel: .success)
    }
    
    func loadDataValue() -> Data? {
        UserDefaults.standard.data(forKey: rawValue)
    }
    
    func loadStringValue() -> String? {
        UserDefaults.standard.string(forKey: rawValue)
    }
    
    func loadBoolValue() -> Bool {
        UserDefaults.standard.bool(forKey: rawValue)
    }
    
    func removeValue() {
        UserDefaults.standard.removeObject(forKey: rawValue)
//        SVLogger.main.log(message: "User preference removed", info: "Key: \(rawValue)", logLevel: .success)
    }
}

extension UserDefaults {
    func resetCache() { UserPreferenceKeys.allCases.forEach { removeObject(forKey: $0.rawValue) } }
    
    internal func save(_ value: Any, for key: UserPreferenceKeys) { key.save(value) }
    
    internal func loadData(key: UserPreferenceKeys) -> Data? { key.loadDataValue() }
    
    internal func load(key: UserPreferenceKeys) -> Any? { key.loadDataValue() }
    
    internal func remove(key: UserPreferenceKeys) { key.removeValue() }
}
