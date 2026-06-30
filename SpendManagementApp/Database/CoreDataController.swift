//
//  CoreDataController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 14/09/2025.
//

import UIKit
import CoreData

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    // User defaults
    var defaults: UserDefaults
    
    // Multicast delegate
    var listeners = MulticastDelegate<DatabaseListener>()
    
    // Core Data
    var persistentContainer: NSPersistentContainer
    
    // NSFetchedResultsController instances
    var allRecordsFetchedResultsController: NSFetchedResultsController<Record>?
    var allCategoriesFetchedResultsController: NSFetchedResultsController<Category>?
    var allBudgetsFetchedResultsController: NSFetchedResultsController<Budget>?
    var allNotificationsFetchedResultsController: NSFetchedResultsController<AppNotification>?
    var allConversionRatesFetchedResultsController: NSFetchedResultsController<ConversionRate>?
    
    // Stored base currency code in UserDefaults
    var currencyBaseCode: String {
        get { return defaults.string(forKey: "CurrencyBaseCode") ?? "" }
        set { defaults.set(newValue, forKey: "CurrencyBaseCode") }
    }
    
    // Stored current balance in UserDefaults
    var currentBalance: Double {
        get { return defaults.double(forKey: "CurrentBalance") }
        set { defaults.set(newValue, forKey: "CurrentBalance") }
    }
    
    // Flag that determine whether current balance has set initially
    var initialCurrentBalance: Bool {
        get { return defaults.bool(forKey: "InitialCurrentBalance") }
        set { defaults.set(true, forKey: "InitialCurrentBalance") }
    }
    
    override init() {
        // Set up Core Data model container and load persistent stores
        persistentContainer = NSPersistentContainer(name: "DataModel")
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        }
        defaults = UserDefaults.standard
        
        // Used to debug
//        defaults.removeObject(forKey: "InitialCurrentBalance")
//        defaults.removeObject(forKey: "CurrentBalance")
//        defaults.removeObject(forKey: "CurrencyBaseCode")
        
        super.init()
        
        // Ensure base currency defaults to AUD
        if currencyBaseCode == "" {
            currencyBaseCode = "AUD"
        }
        
        // Ensure at least one conversion rate exists
        if fetchAllConvensionRates().isEmpty {
            let _ = addConversionRate(code: currencyBaseCode, rate: 1.0)
        }
    }
    
    // Saves pending changes on the view context
    func cleanup() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("Failed to save changes to Core Data with error: \(error)")
            }
        }
    }
    
    // Add a listener and immediately push the latest changes
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        
        if listener.listenerType == .records {
            listener.onRecordsChange(records: fetchAllRecords())
        }
        
        if listener.listenerType == .categories {
            listener.onCategoriesChange(categories: fetchAllCategories())
        }
        
        if listener.listenerType == .budgets {
            listener.onBudgetsChange(budgets: fetchAllBudgets())
        }
        
        if listener.listenerType == .notifications {
            listener.onNotificationsChange(notifications: fetchAllNotifications())
        }
        
        if listener.listenerType == .conversionRates {
            listener.onConversionRatesChange(conversionRates: fetchAllConvensionRates())
        }
    }
    
    // Remove a listener
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    // MARK: - Record methods for database
    
    // Create a new Record and update currentBalance + budget notifications if needed
    func addRecord(date: Date, amount: Decimal, location: String, note: String, category: Category, conversionCode: String) -> Record {
        let record = Record(context: persistentContainer.viewContext)
        
        record.date = date
        record.amount = amount as NSDecimalNumber
        record.location = location
        record.note = note
        record.categories = category
        record.conversionCode = conversionCode
        
        // Update currentBalance based on conversion rate and sign by type
        if let rcdAmount = record.amount?.doubleValue {
            let rate = getConversionRate(from: conversionCode).rate?.doubleValue
            let convertAmount = rcdAmount / rate!
            let sign: Double = category.financialType == .expense ? -convertAmount : convertAmount
            let am: Double = defaults.double(forKey: "CurrentBalance") + sign
            currentBalance = am
        }
        
        // Check the percentage for each budget, if ≥ 80% then create notifications
        if let budgets = category.budgets as? Set<Budget> {
            for budget in budgets {
                if budget.totalPercentageSpent >= 80, let amount = budget.amount as? Decimal {
                    // Make sure only one notification per budget at a time
                    guard budget.notifications == nil else {
                        break
                    }
                    
                    // Only notify for active budgets (today within range)
                    let today = Date().startOfDay
                    guard let sd = budget.startDate, sd <= today, let ed = budget.endDate, today <= ed else {
                        break
                    }
                    
                    let title: String
                    let message: String
                    if budget.totalPercentageSpent >= 100 {
                        title = "Overspending for budget: \(budget.name ?? "")"
                        message = "Your budget has been completely drained. You should stop spending now!"
                    } else {
                        title = "Close to overspending for budget: \(budget.name ?? "")"
                        message = "Your current spending is close to reaching your budget limit. You should consider cutting back!"
                    }
                    let _ = addNotification(title: title, message: message, amount1: budget.totalSpent, amount2: amount, budget: budget)
                }
            }
        }
        
        return record
    }
    
    // Update existing Record and re-calculate the currentBalance
    func updateRecord(record: Record, date: Date, amount: Decimal, location: String, note: String, category: Category, conversionCode: String) -> Record {
        // Reverse the previous record's impact on currentBalance
        if let rcdAmount = record.amount?.doubleValue, let cat = record.categories {
            var am: Double = defaults.double(forKey: "CurrentBalance")
            
            let rate = getConversionRate(from: conversionCode).rate?.doubleValue
            
            var convertAmount = rcdAmount / rate!
            if cat.financialType == .expense {
                am += convertAmount
            } else {
                am -= convertAmount
            }
            
            // Apply the new values to currentBalance
            let newAmount = (amount as NSDecimalNumber).doubleValue
            convertAmount = newAmount / rate!
            let sign: Double = category.financialType == .expense ? -convertAmount : convertAmount
            am = am + sign
            currentBalance = am
        }
        
        // Persist updated fields
        record.date = date
        record.amount = amount as NSDecimalNumber
        record.location = location
        record.note = note
        record.categories = category
        record.conversionCode = conversionCode
        
        return record
    }
    
    // Delete a record and reverse its effect on currentBalance
    func deleteRecord(record: Record) {
        // Update currentBalance based on conversion rate and sign by type
        if let rcdAmount = record.amount?.doubleValue {
            let rate = getConversionRate(from: record.conversionCode!).rate?.doubleValue
            let convertAmount = rcdAmount / rate!
            let sign: Double = record.categories!.financialType == .expense ? convertAmount : -convertAmount
            let am: Double = defaults.double(forKey: "CurrentBalance") + sign
            currentBalance = am
        }
        
        persistentContainer.viewContext.delete(record)
    }
    
    // Remove all records and reset current balance
    func clearRecord() {
        let allRecord = fetchAllRecords()
        
        for record in allRecord {
            deleteRecord(record: record)
        }
        
        currentBalance = 0.0
    }
    
    // MARK: - Category methods for database
    
    // Check the category name exist or not
    func checkCategoryExist(name: String, type: FinancialType) -> Bool {
        let categories = fetchAllCategories().filter { $0.financialType == type }
        let checkCategory = categories.filter { $0.name?.lowercased() == name.lowercased() }
        
        if !checkCategory.isEmpty {
            return true
        }
        return false
    }
    
    // Add a new Category
    func addCategory(name: String, type: FinancialType) -> Category? {
        if checkCategoryExist(name: name, type: type) {
            return nil
        }
        
        let category = Category(context: persistentContainer.viewContext)
        
        category.name = name
        category.financialType = type
        
        return category
    }
    
    // Update existing Category
    func updateCategory(category: Category, name: String, type: FinancialType) -> Category? {
        if checkCategoryExist(name: name, type: type) {
            return nil
        }
        
        category.name = name
        category.financialType = type
        
        return category
    }
    
    // Delete Category
    func deleteCategory(category: Category) {
        persistentContainer.viewContext.delete(category)
    }
    
    // MARK: - Budget methods for database
    
    // Create a new Budget
    func addBudget(name: String, amount: Decimal, startDate: Date, endDate: Date, categories: [Category]) -> Budget {
        let budget = Budget(context: persistentContainer.viewContext)
        
        budget.name = name
        budget.amount = amount as NSDecimalNumber
        budget.startDate = startDate
        budget.endDate = endDate
        
        for cat in categories {
            budget.addToCategories(cat)
        }
        
        return budget
    }
    
    // Update existing Budget
    func updateBudget(budget: Budget, name: String, amount: Decimal, startDate: Date, endDate: Date, categories: [Category]) -> Budget {
        budget.name = name
        budget.amount = amount as NSDecimalNumber
        budget.startDate = startDate
        budget.endDate = endDate
        
        // Remove previous links
        let current = (budget.categories as? Set<Category>) ?? []
        for cat in current {
            budget.removeFromCategories(cat)
        }
        
        // Add new links
        for cat in categories {
            budget.addToCategories(cat)
        }
        
        return budget
    }
    
    // Delete Budget
    func deleteBudget(budget: Budget) {
        persistentContainer.viewContext.delete(budget)
    }
    
    // Clear budget
    func clearBudget() {
        for budget in fetchAllBudgets() {
            deleteBudget(budget: budget)
        }
    }
    
    // MARK: - Notification methods for database
    
    // Create an AppNotification
    func addNotification(title: String, message: String, amount1: Decimal, amount2: Decimal, budget: Budget) -> AppNotification {
        let notification = AppNotification(context: persistentContainer.viewContext)
        
        notification.title = title
        notification.message = message
        notification.date = Date().startOfDay
        notification.amount1 = amount1 as NSDecimalNumber
        notification.amount2 = amount2 as NSDecimalNumber
        notification.budgets = budget
        
        setupNotification(notification: notification)
        
        return notification
    }
    
    // Delete AppNotification
    func deleteNotification(notification: AppNotification) {
        persistentContainer.viewContext.delete(notification)
    }
    
    // Clear Notification
    func clearNotification() {
        for notification in fetchAllNotifications() {
            deleteNotification(notification: notification)
        }
    }
    
    // Fire a local notification
    func setupNotification(notification: AppNotification) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let appDelegate = appDelegate, appDelegate.notificationsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = notification.title ?? ""
        content.body = notification.message ?? ""

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let identifier = AppDelegate.NOTIFICATION_IDENTIFIER + UUID().uuidString

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // MARK: - ConversionRate methods for database
    
    // Add conversion rate
    func addConversionRate(code: String, rate: Decimal) -> ConversionRate {
        let conversionRate = ConversionRate(context: persistentContainer.viewContext)
        
        conversionRate.code = code
        conversionRate.rate = rate as NSDecimalNumber
        conversionRate.isSub = false
        
        return conversionRate
    }
    
    // Delete conversion rate
    func deleteConversionRate(conversionRate: ConversionRate) {
        persistentContainer.viewContext.delete(conversionRate)
    }
    
    // Remove all conversion rates
    func clearConversionRate() {
        let allRates = fetchAllConvensionRates()
        for cr in allRates {
            let _ = deleteConversionRate(conversionRate: cr)
        }
    }
    
    // Mark a conversion rate as "sub currency"
    func addSubCurrency(convensionRate: ConversionRate) -> ConversionRate {
        convensionRate.isSub = true
        return convensionRate
    }
    
    // Unmark a conversion rate as "sub currency"
    func deleteSubCurrency(convensionRate: ConversionRate) {
        convensionRate.isSub = false
    }
    
    // Restore multiple sub currencies by code
    func setupSubCurrencies(subCurrencies: [String]) {
        let allRates = fetchAllConvensionRates()
        for rate in allRates {
            for cr in subCurrencies {
                if rate.code == cr {
                    let _ = addSubCurrency(convensionRate: rate)
                    break
                }
            }
        }
    }
    
    // Count number of sub currencies
    func countSubCurrencies() -> Int {
        var count = 0
        for cr in fetchAllConvensionRates() {
            if cr.isSub {
                count += 1
            }
        }
        return count
    }
    
    // Clear all sub currency
    func clearSubCurrency() {
        for cr in fetchAllConvensionRates() {
            deleteSubCurrency(convensionRate: cr)
        }
    }
    
    // MARK: - Fetched Results Controller Protocol methods
    
    // Called after controller detects changes
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == allRecordsFetchedResultsController {
            listeners.invoke { listener in
                if listener.listenerType == .records {
                    listener.onRecordsChange(records: fetchAllRecords())
                }
            }
        } else if controller == allCategoriesFetchedResultsController {
            listeners.invoke { (listener) in
                if listener.listenerType == .categories {
                    listener.onCategoriesChange(categories: fetchAllCategories())
                }
            }
        } else if controller == allBudgetsFetchedResultsController {
            listeners.invoke { (listener) in
                if listener.listenerType == .budgets {
                    listener.onBudgetsChange(budgets: fetchAllBudgets())
                }
            }
        } else if controller == allNotificationsFetchedResultsController {
            listeners.invoke { (listener) in
                if listener.listenerType == .notifications {
                    listener.onNotificationsChange(notifications: fetchAllNotifications())
                }
            }
        } else if controller == allConversionRatesFetchedResultsController {
            listeners.invoke { (listener) in
                if listener.listenerType == .conversionRates {
                    listener.onConversionRatesChange(conversionRates: fetchAllConvensionRates())
                }
            }
        }
    }
    
    // MARK: - Record Fetching data methods
    
    // Return all Records
    func fetchAllRecords() -> [Record] {
        if allRecordsFetchedResultsController == nil {
            let request: NSFetchRequest<Record> = Record.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "date" , ascending: false)
            request.sortDescriptors = [nameSortDescriptor]
            
            allRecordsFetchedResultsController = NSFetchedResultsController<Record>(
                fetchRequest: request,
                managedObjectContext: persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            allRecordsFetchedResultsController?.delegate = self
            
            do {
                try allRecordsFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let records = allRecordsFetchedResultsController?.fetchedObjects {
            return records
        }
        
        return [Record]()
    }
    
    // Filter records by month and year
    func fetchRecordsBasedOnMonthAndYear(month: Int, year: Int) -> [Record] {
        let cal = Calendar.current
        let records = fetchAllRecords().filter {
            guard let date = $0.date else {
                return false
            }
            
            return cal.component(.month, from: date) == month && cal.component(.year, from: date) == year
        }
        return records
    }
    
    // MARK: - Category Fetching data methods
    
    // Return all Categories
    func fetchAllCategories() -> [Category] {
        if allCategoriesFetchedResultsController == nil {
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "type" , ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            allCategoriesFetchedResultsController = NSFetchedResultsController<Category>(
                fetchRequest: request,
                managedObjectContext: persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            allCategoriesFetchedResultsController?.delegate = self
            
            do {
                try allCategoriesFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let categories = allCategoriesFetchedResultsController?.fetchedObjects {
            return categories
        }
        
        return [Category]()
    }
    
    // MARK: - Budget Fetching data methods
    
    // Return all Budgets
    func fetchAllBudgets() -> [Budget] {
        if allBudgetsFetchedResultsController == nil {
            let request: NSFetchRequest<Budget> = Budget.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name" , ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            allBudgetsFetchedResultsController = NSFetchedResultsController<Budget>(
                fetchRequest: request,
                managedObjectContext: persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            allBudgetsFetchedResultsController?.delegate = self
            
            do {
                try allBudgetsFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let budgets = allBudgetsFetchedResultsController?.fetchedObjects {
            return budgets
        }
        
        return [Budget]()
    }
    
    // MARK: - Notification Fetching data methods
    
    // Return all Notifications
    func fetchAllNotifications() -> [AppNotification] {
        if allNotificationsFetchedResultsController == nil {
            let request: NSFetchRequest<AppNotification> = AppNotification.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "date" , ascending: false)
            request.sortDescriptors = [nameSortDescriptor]
            
            allNotificationsFetchedResultsController = NSFetchedResultsController<AppNotification>(
                fetchRequest: request,
                managedObjectContext: persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            allNotificationsFetchedResultsController?.delegate = self
            
            do {
                try allNotificationsFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let notifications = allNotificationsFetchedResultsController?.fetchedObjects {
            return notifications
        }
        
        return [AppNotification]()
    }
    
    // MARK: - ConversionRate Fetching data methods
    
    // Return all Conversion Rates
    func fetchAllConvensionRates() -> [ConversionRate] {
        if allConversionRatesFetchedResultsController == nil {
            let request: NSFetchRequest<ConversionRate> = ConversionRate.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "code" , ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            allConversionRatesFetchedResultsController = NSFetchedResultsController<ConversionRate>(
                fetchRequest: request,
                managedObjectContext: persistentContainer.viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            allConversionRatesFetchedResultsController?.delegate = self
            
            do {
                try allConversionRatesFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let conversionRates = allConversionRatesFetchedResultsController?.fetchedObjects {
            return conversionRates
        }
        
        return [ConversionRate]()
    }
    
    // Get the base currency ConversionRate
    func getBaseConversionRate() -> ConversionRate {
        return fetchAllConvensionRates().filter { $0.code == currencyBaseCode }.first!
    }
    
    // Get a rate by code
    func getConversionRate(from code: String) -> ConversionRate {
        return fetchAllConvensionRates().filter { $0.code == code }.first!
    }
    
    // MARK: - Chart Data Fetching methods
    
    // Build category totals for a month and year filtered by financial type
    func fetchCategoriesBasedOnFinancialType(for type: FinancialType, month: Int, year: Int) -> [CategorySummary] {
        var records = fetchRecordsBasedOnMonthAndYear(month: month, year: year)
        records = records.filter { $0.categories?.financialType == type }
        
        // Group records by category name and sum amounts
        let grouped = Dictionary(grouping: records) { $0.categories?.name ?? "Uncategorized" }
        let summaries: [CategorySummary] = grouped.map { key, values in
            var total: Double = 0
            for record in values {
                let rate = getConversionRate(from: record.conversionCode!).rate?.doubleValue
                if let amount = record.amount?.doubleValue {
                    total += (amount / rate!)
                }
            }
            return CategorySummary(categoryName: key, totalAmount: total)
        }
        
        return summaries
    }
    
    // Build daily income/expense totals across a month for overview charts
    func fetchOverviewBasedOnFinancialType(month: Int, year: Int) -> [OverviewSummary] {
        struct DateType: Hashable {
            var day: Date
            var type: FinancialType
        }
        
        // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to get all the days in a specific month. The output (here) was showing how to use Calendar.current.range to get all days range in the specific month.
        let cal = Calendar.current
        let startOfMonth = cal.date(from: DateComponents(year: year, month: month, day: 1))
        let range = cal.range(of: .day, in: .month, for: startOfMonth ?? Date())
        
        // Generate all days in the selected month
        var days: [Date] = []
        if let range = range {
            for day in range {
                if let d = cal.date(from: DateComponents(year: year, month: month, day: day)) {
                    days.append(d)
                }
            }
        }
        
        let records = fetchRecordsBasedOnMonthAndYear(month: month, year: year)
        
        if records.isEmpty {
            return []
        }
        
        // [DateType: [Record]]
        let grouped = Dictionary(grouping: records) { record in
            let dateRecord = cal.startOfDay(for: record.date ?? Date())
            let type = record.categories?.financialType ?? .unknown
            
            return DateType(day: dateRecord, type: type)
        }
        
        // Sum totals for each DateType then become [DateType: Double]
        var totals: [DateType: Double] = [:]
        for (key, values) in grouped {
            var total: Double = 0
            for record in values {
                let rate = getConversionRate(from: record.conversionCode!).rate?.doubleValue
                if let amount = record.amount?.doubleValue {
                    total += (amount / rate!)
                }
            }
            totals[key] = total
        }
        
        // Build summaries for every day for both income and expense
        var summaries: [OverviewSummary] = []
        for day in days {
            for type in [FinancialType.income, .expense] {
                let key = DateType(day: day, type: type)
                let total = totals[key] ?? 0
                let signed = type == .expense ? -total : total
                summaries.append(OverviewSummary(date: day, type: type, totalAmount: signed))
            }
        }
        
        // Sort by date then by type
        return summaries.sorted {
            if $0.date == $1.date {
                return $0.type.rawValue < $1.type.rawValue
            } else {
                return $0.date < $1.date
            }
        }
    }
    
    // Build totals by location for a month and year filtered by financial type
    func fetchLocationsBasedOnFinancialType(for type: FinancialType, month: Int, year: Int) -> [LocationSummary] {
        var records = fetchRecordsBasedOnMonthAndYear(month: month, year: year)
        records = records.filter { $0.categories?.financialType == type }
        
        // Group by location and sum amounts
        let grouped = Dictionary(grouping: records) { $0.location ?? "No Location" }
        let summaries: [LocationSummary] = grouped.map { key, values in
            var total: Double = 0
            for record in values {
                let rate = getConversionRate(from: record.conversionCode!).rate?.doubleValue
                if let amount = record.amount?.doubleValue {
                    total += (amount / rate!)
                }
            }
            return LocationSummary(locationName: key, totalAmount: total)
        }
        
        return summaries
    }
}
