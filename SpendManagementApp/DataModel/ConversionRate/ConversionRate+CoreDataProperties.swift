//
//  ConversionRate+CoreDataProperties.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 16/10/2025.
//
//

import Foundation
import CoreData


extension ConversionRate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversionRate> {
        return NSFetchRequest<ConversionRate>(entityName: "ConversionRate")
    }

    @NSManaged public var code: String?
    @NSManaged public var isSub: Bool
    @NSManaged public var rate: NSDecimalNumber?

}

extension ConversionRate : Identifiable {

}
