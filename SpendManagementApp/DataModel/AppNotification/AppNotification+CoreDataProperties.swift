//
//  AppNotification+CoreDataProperties.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 12/10/2025.
//
//

import Foundation
import CoreData


extension AppNotification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppNotification> {
        return NSFetchRequest<AppNotification>(entityName: "AppNotification")
    }

    @NSManaged public var message: String?
    @NSManaged public var amount1: NSDecimalNumber?
    @NSManaged public var amount2: NSDecimalNumber?
    @NSManaged public var title: String?
    @NSManaged public var date: Date?
    @NSManaged public var budgets: Budget?

}

extension AppNotification : Identifiable {

}
