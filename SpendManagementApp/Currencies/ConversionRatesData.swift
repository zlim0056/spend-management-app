//
//  ConversionRatesData.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 12/10/2025.
//

import UIKit

class ConversionRatesData: NSObject, Decodable {
    // Dictionary to store all currency conversion rates
    var conversionRates: [String: Decimal]?
    
    // Map JSON key "conversion_rates" to the property name
    private enum CodingKeys: String, CodingKey {
        case conversionRates = "conversion_rates"
    }
    
    required init(from decoder: Decoder) throws {
        // Create a keyed container using the defined coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode the "conversion_rates" field to a dictionary
        conversionRates = try container.decode([String: Decimal].self, forKey: .conversionRates)
    }
}
