//
//  Record+CoreDataProperties.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 16/10/2025.
//
//

import Foundation
import CoreData


extension Record {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Record> {
        return NSFetchRequest<Record>(entityName: "Record")
    }

    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var date: Date?
    @NSManaged public var location: String?
    @NSManaged public var note: String?
    @NSManaged public var conversionCode: String?
    @NSManaged public var categories: Category?

}

extension Record : Identifiable {

}
