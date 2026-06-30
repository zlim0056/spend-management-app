//
//  DatabaseProtocol.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 14/09/2025.
//

import Foundation

enum ListenerType {
    case records
    case categories
    case budgets
    case notifications
    case conversionRates
}

protocol DatabaseListener: AnyObject {
    // Declares the type of updates this listener wants to receive
    var listenerType: ListenerType { get set }
    
    // Callbacks invoked when data changes
    func onRecordsChange(records: [Record])
    func onCategoriesChange(categories: [Category])
    func onBudgetsChange(budgets: [Budget])
    func onNotificationsChange(notifications: [AppNotification])
    func onConversionRatesChange(conversionRates: [ConversionRate])
}

protocol DatabaseProtocol: AnyObject {
    // Global currency base code
    var currencyBaseCode: String { get set }
    
    // Current balance and whether it has been set initially
    var currentBalance: Double { get set }
    var initialCurrentBalance: Bool { get set }
    
    func cleanup()
    
    // Listener management (subscribe/unsubscribe to updates)
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    // Record methods
    func addRecord(date: Date, amount: Decimal, location: String, note: String, category: Category, conversionCode: String) -> Record
    func updateRecord(record: Record, date: Date, amount: Decimal, location: String, note: String, category: Category, conversionCode: String) -> Record
    func deleteRecord(record: Record)
    
    // Category methods
    func addCategory(name: String, type: FinancialType) -> Category?
    func updateCategory(category: Category, name: String, type: FinancialType) -> Category?
    func deleteCategory(category: Category)
    
    // Budget methods
    func addBudget(name: String, amount: Decimal, startDate: Date, endDate: Date, categories: [Category]) -> Budget
    func updateBudget(budget: Budget, name: String, amount: Decimal, startDate: Date, endDate: Date, categories: [Category]) -> Budget
    func deleteBudget(budget: Budget)
    
    // Notification methods
    func addNotification(title: String, message: String, amount1: Decimal, amount2: Decimal, budget: Budget) -> AppNotification
    func deleteNotification(notification: AppNotification)
    
    // ConversionRate methods
    func addConversionRate(code: String, rate: Decimal) -> ConversionRate
    func deleteConversionRate(conversionRate: ConversionRate)
}
