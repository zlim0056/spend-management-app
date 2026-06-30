//
//  DatePicker.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 21/09/2025.
//
import UIKit

// Used to notify another ViewController when the user selects a month and year
protocol MonthYearPickerDelegate: AnyObject {
    func monthYearPicker(month: Int, year: Int)
}

class MonthYearPicker: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    let picker = UIPickerView()
    
    // Array of month names (January...December)
    let months = Calendar.current.monthSymbols
    
    // Array of available years
    var years: [Int] = []
    
    // Delegate reference to modify text field in different ViewController
    weak var delegate: MonthYearPickerDelegate?

    // Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPicker()
    }

    // Initializer
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPicker()
    }
    
    // Get current month-year as formatted string
    func currentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: Date())
    }

    // Configures picker view and default selection
    func setupPicker() {
        picker.delegate = self
        picker.dataSource = self
        addSubview(picker)
        
        // Fit picker inside the custom UIView
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: trailingAnchor),
            picker.topAnchor.constraint(equalTo: topAnchor),
            picker.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Prepare list of years from 1 to current year
        let currentYear = Calendar.current.component(.year, from: Date())
        years = Array(1...currentYear)
        
        // Select the current month and year in picker
        let currentMonth = Calendar.current.component(.month, from: Date()) - 1
        if let yearIndex = years.firstIndex(of: currentYear) {
            picker.selectRow(currentMonth, inComponent: 0, animated: false)
            picker.selectRow(yearIndex, inComponent: 1, animated: false)
        }
    }

    // MARK: - UIPickerView DataSource
    
    // Only 2 components (month and year)
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    // Return count based on which component (0=month, 1=year)
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? months.count : years.count
    }

    // MARK: - UIPickerView Delegate
    
    // Display all selectable row in the picker
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return component == 0 ? months[row] : "\(years[row])"
    }

    // When user select a month or year, then execute this
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Get selected month and year
        let monthIndex = picker.selectedRow(inComponent: 0)
        let yearIndex = picker.selectedRow(inComponent: 1)
        
        // Modify other view controller's date picker to display
        delegate?.monthYearPicker(month: monthIndex + 1, year: years[yearIndex])
    }
}
