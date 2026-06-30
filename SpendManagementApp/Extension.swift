//
//  UIViewController+displayMessage.swift
//  FIT3178-W03-Lab
//
//  Created by Zi You Lim on 13/08/2025.
//

import UIKit
import SwiftUI

// MARK: - UITextField Styling Extension

extension UITextField {
    // Adds a simple border and rounded corners to text fields for consistent UI design
    func styled() {
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 8
        self.layer.borderColor = UIColor.separator.cgColor
    }
}

// MARK: - UIViewController Alert Extension

extension UIViewController {
    // Displays an alert with a given title and message
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Decimal Formatting Extension

extension Decimal {
    // Formats numeric values as currency strings with color coding
    func formatted(type: FinancialType, currencyCode: String? = nil) -> (String, UIColor) {
        var baseCode: String? = currencyCode
        
        // If no currency code provided, fetch the base currency from Core Data
        if currencyCode == nil {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let databaseController = appDelegate?.databaseController
            baseCode = databaseController?.currencyBaseCode
        }
        
        // Format numeric value with 2 decimal places
        let amountString = String(format: "%.2f", NSDecimalNumber(decimal: self).doubleValue)
        
        // Get currency symbol for the selected locale
        // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to get the currency symbol by using country code from specific country. The output (here) was showing the usage of NumberFormatter, combine with Locale() can get the currency symbol.
        let locale = Locale(identifier: "en_AU")
        let nf = NumberFormatter()
        nf.locale = locale
        nf.currencyCode = baseCode
        let symbol = nf.currencySymbol ?? ""
        
        // Return formatted string with color coding:
        // Green = income, Red = expense, White = neutral
        if type == .income {
            return ("+\(symbol) \(amountString)", .systemGreen)
        } else if type == .expense {
            return ("-\(symbol) \(amountString)", .systemRed)
        } else {
            if self >= 0 {
                return ("\(symbol) \(amountString)", .white)
            } else {
                return ("-\(symbol) \(String(amountString.dropFirst()))", .white)
            }
        }
    }
}

// MARK: - Date Formatting Extension

extension Date {
    // Get the start of the day of specific date (00:00 of the day)
    var startOfDay: Date {
        return Calendar.autoupdatingCurrent.startOfDay(for: self)
    }
    
    // Get the next date of specific date
    var nextDay: Date {
        return Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: self) ?? Date()
    }
    
    // Get the day from specific date (Mon, Tue, ...)
    var dateStringWithDay: String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .autoupdatingCurrent
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.locale = Locale(identifier: "en_AU_POSIX")
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: self)
    }
    
    // Get the number of day from specific date (03 -> 03-01-2025)
    var dateStringWithDayNumber: String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .autoupdatingCurrent
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.locale = Locale(identifier: "en_AU_POSIX")
        dateFormatter.dateFormat = "dd"
        return dateFormatter.string(from: self)
    }
    
    // Get the date string and include title for (Today, Yesterday, Tomorrow)
    var dateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .autoupdatingCurrent
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: self)
        
        let today = Date().startOfDay
        if self.startOfDay == today {
            return "\(dateString) (Today)"
        }
        
        if self.startOfDay == Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: today) {
            return "\(dateString) (Yesterday)"
        }
        
        if self.startOfDay == Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: today) {
            return "\(dateString) (Tomorrow)"
        }
        
        return dateString
    }
    
    // Get the days left between specific date and input
    func daysLeft(to endDate: Date) -> Int {
        return Calendar.autoupdatingCurrent.dateComponents([.day], from: self, to: endDate).day ?? 0
    }
}

// MARK: - UITableViewCell Progress Bar Integration

extension UITableViewCell {
    // Embeds a SwiftUI ProgressBar
    func createProgressBar(container: UIView, amount1: CGFloat, amount2: CGFloat) {
        let initialProgressBar = ProgressBar(amount1: amount1, amount2: amount2)
        let hostingController = UIHostingController(rootView: initialProgressBar)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: container.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
    }
}

// MARK: - Helper Function

// Converts a "MMMM yyyy" string ("October 2025") to a MonthAndYear struct
func monthYearToInts(_ dateString: String) -> MonthAndYear? {
    let df = DateFormatter()
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    
    df.dateFormat = "MMMM yyyy"
    if let date = df.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines)) {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.month, .year], from: date)
        if let m = comps.month, let y = comps.year {
            return MonthAndYear(month: m, year: y)
        }
    }
    
    return nil
}
