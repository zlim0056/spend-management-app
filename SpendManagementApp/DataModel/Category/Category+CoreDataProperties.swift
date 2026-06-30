//
//  Category+CoreDataProperties.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 12/10/2025.
//
//

import Foundation
import CoreData

enum FinancialType: Int32 {
    case expense = 0
    case income = 1
    case unknown = 2
}

extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var name: String?
    @NSManaged public var type: Int32
    @NSManaged public var budgets: NSSet?
    @NSManaged public var records: NSSet?

}

// MARK: Generated accessors for budgets
extension Category {

    @objc(addBudgetsObject:)
    @NSManaged public func addToBudgets(_ value: Budget)

    @objc(removeBudgetsObject:)
    @NSManaged public func removeFromBudgets(_ value: Budget)

    @objc(addBudgets:)
    @NSManaged public func addToBudgets(_ values: NSSet)

    @objc(removeBudgets:)
    @NSManaged public func removeFromBudgets(_ values: NSSet)

}

// MARK: Generated accessors for records
extension Category {

    @objc(addRecordsObject:)
    @NSManaged public func addToRecords(_ value: Record)

    @objc(removeRecordsObject:)
    @NSManaged public func removeFromRecords(_ value: Record)

    @objc(addRecords:)
    @NSManaged public func addToRecords(_ values: NSSet)

    @objc(removeRecords:)
    @NSManaged public func removeFromRecords(_ values: NSSet)

}

extension Category : Identifiable {

}

extension Category {
    var financialType: FinancialType {
        get {
            return FinancialType(rawValue: self.type)!
        }
        
        set {
            self.type = newValue.rawValue
        }
    }
}
