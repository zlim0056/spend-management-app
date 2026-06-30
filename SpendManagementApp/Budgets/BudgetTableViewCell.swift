//
//  BudgetTableViewCell.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 04/10/2025.
//

import UIKit
import SwiftUI

class BudgetTableViewCell: UITableViewCell {
    
    @IBOutlet weak var budgetNameLabel: UILabel!
    @IBOutlet weak var daysLeftLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var progressBar: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Round the daysLeft label corners and set text color
        daysLeftLabel.layer.masksToBounds = true
        daysLeftLabel.layer.cornerRadius = 5
        daysLeftLabel.textColor = .white
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // Configure the cell using a Budget object
    func configure(budget: Budget) {
        // Display budget name
        budgetNameLabel.text = budget.name
        
        // Check that both start and end dates are available
        if let sd = budget.startDate, let ed = budget.endDate {
            let today = Date().startOfDay
            
            // Determine and display budget status (active, not started, expired)
            if sd <= today && today < ed {
                // Budget currently active
                daysLeftLabel.text = "\(today.daysLeft(to: ed))d left"
                daysLeftLabel.layer.backgroundColor = Color(red: 50/255, green: 200/255, blue: 50/255).cgColor
            } else if ed == today {
                // Budget expires today
                daysLeftLabel.text = "Expired today"
                daysLeftLabel.layer.backgroundColor = Color(red: 50/255, green: 200/255, blue: 50/255).cgColor
            } else if sd > today {
                // Budget not yet started
                daysLeftLabel.text = "Not Started"
                daysLeftLabel.layer.backgroundColor = UIColor.lightGray.cgColor
            } else {
                // Budget already expired
                daysLeftLabel.text = "Expired"
                daysLeftLabel.layer.backgroundColor = UIColor.systemRed.cgColor
            }
            
            // Show formatted start and end dates
            startDateLabel.text = sd.dateString
            endDateLabel.text = ed.dateString
            
            // Create and update the progress bar
            if let amount2 = budget.amount as? Decimal {
                let a1 = CGFloat(NSDecimalNumber(decimal: budget.totalSpent).doubleValue)
                let a2 = CGFloat(NSDecimalNumber(decimal: amount2).doubleValue)
                createProgressBar(container: progressBar, amount1: a1, amount2: a2)
            }
        }
    }
}
