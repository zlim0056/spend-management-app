//
//  Budget+CoreDataProperties.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 12/10/2025.
//
//

import Foundation
import CoreData


extension Budget {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Budget> {
        return NSFetchRequest<Budget>(entityName: "Budget")
    }

    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var endDate: Date?
    @NSManaged public var name: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var categories: NSSet?
    @NSManaged public var notifications: AppNotification?

}

// MARK: Generated accessors for categories
extension Budget {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: Category)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: Category)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

extension Budget : Identifiable {

}

extension Budget {
    // Calculate total amount spent under this budget’s categories
    var totalSpent: Decimal {
        var amount: Decimal = 0
        
        if let categories = self.categories as? Set<Category> {
            for cat in categories {
                for rcd in (cat.records as? Set<Record> ?? []) {
                    if let rcdDate = rcd.date {
                        // Count only records within the budget date range
                        if self.startDate! <= rcdDate, rcdDate < self.endDate!.nextDay {
                            amount += (rcd.amount as? Decimal ?? 0)
                        }
                    }
                }
            }
        }
        
        return amount
    }
    
    // Calculate percentage of budget used
    var totalPercentageSpent: Decimal {
        if let amount = self.amount as? Decimal {
            return (self.totalSpent / amount) * 100
        }
        return 0
    }
}
