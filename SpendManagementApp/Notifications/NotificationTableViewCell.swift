//
//  NotificationTableViewCell.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 12/10/2025.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var progressBar: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // MARK: - Configuration
    
    // Configures the cell to display data from AppNotification
    func configure(notification: AppNotification) {
        // Set the main text fields
        titleLabel.text = notification.title
        messageLabel.text = notification.message
        
        // Make progress bar
        if let amount1 = notification.amount1 as? Decimal, let amount2 = notification.amount2 as? Decimal {
            let a1 = CGFloat(NSDecimalNumber(decimal: amount1).doubleValue)
            let a2 = CGFloat(NSDecimalNumber(decimal: amount2).doubleValue)
            createProgressBar(container: progressBar, amount1: a1, amount2: a2)
        }
    }
}
