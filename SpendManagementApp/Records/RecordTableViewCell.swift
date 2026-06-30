//
//  RecordsTableViewCell.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 13/09/2025.
//

import UIKit

class RecordTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dayLabel: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // MARK: - Configuration
        
    // Configures the table cell using data from a Record
    func configure(record: Record) {
        // Set date values
        dayLabel.setTitle(record.date?.dateStringWithDay, for: .normal)
        dateLabel.text = " " + (record.date?.dateStringWithDayNumber ?? "")
        
        // Set category and amount info
        if let category = record.categories {
            categoryLabel.text = category.name
            
            // Format the amount with color and symbol based on category type
            if let amount = record.amount as? Decimal {
                let (formatted, color) = amount.formatted(type: category.financialType, currencyCode: record.conversionCode)
                amountLabel.text = formatted
                amountLabel.textColor = color
            }
        }
    }
}
