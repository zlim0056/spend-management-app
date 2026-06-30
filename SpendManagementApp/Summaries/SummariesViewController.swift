//
//  SummariesViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 15/09/2025.
//

import UIKit
import SwiftUI

struct MonthAndYear: Equatable {
    let month: Int
    let year: Int
}

class SummariesViewController: UIViewController, MonthYearPickerDelegate {
    
    @IBOutlet weak var chartContainerView: UIView!
    @IBOutlet weak var financialTypePicker: UISegmentedControl!
    @IBOutlet weak var chartTypeButton: UIButton!
    @IBOutlet weak var datePicker: UITextField!
    
    // Used to embed SwiftUI into UIKit
    var hostingController: UIHostingController<AnyView>?
    
    // 0=Category, 1=Overview, 2=Location
    var selectedChartTypeIndex: Int = 0
    
    // Custom month-year picker
    var monthYearPicker: MonthYearPicker?
    
    // Get current selected month and year from date picker
    var selectedMonthYear: MonthAndYear {
        return monthYearToInts(datePicker.text!)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial UI/setup
        setupMonthYearPicker()
        createChart()
        setupChartTypePicker()
        
        // Text field styling
        datePicker.styled()
    }
    
    // Segmented control changed (Income/Expense)
    @IBAction func financialTypePressed(_ sender: Any) {
        updateChart()
    }
    
    // MARK: - Chart methods
    
    // Build a chart view based on current selections
    func makeChart() -> AnyView {
        let financialType = FinancialType(rawValue: Int32(financialTypePicker.selectedSegmentIndex)) ?? .unknown
        let monthAndYear = selectedMonthYear
        
        switch selectedChartTypeIndex {
        case 0:
            return AnyView(CategorySummariesPieChartView(type: financialType, monthAndYear: monthAndYear))
        case 1:
            return AnyView(OverviewSummariesPieChartView(monthAndYear: monthAndYear))
        default:
            return AnyView(LocationSummariesPieChartView(type: financialType, monthAndYear: monthAndYear))
        }
    }
    
    // Replace the current SwiftUI chart with a new one
    func updateChart() {
        let newChart = makeChart()
        hostingController?.rootView = newChart
    }
    
    // Create and embed initial SwiftUI chart
    func createChart() {
        let initialChart = makeChart()
        hostingController = UIHostingController(rootView: initialChart)
        
        guard let hostingController = hostingController else {
            return
        }
        
        // Add SwiftUI view to container
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor)
        ])
    }
    
    // Configure the chart type menu (Category / Overview / Location)
    func setupChartTypePicker() {
        chartTypeButton.menu = UIMenu(
            options: .singleSelection,
            children: [
                UIAction(title: "Category", state: .on, handler: {_ in
                    self.selectedChartTypeIndex = 0
                    self.updateChart()
                    self.financialTypePicker.isHidden = false
                }),
                UIAction(title: "Overview", handler: {_ in
                    self.selectedChartTypeIndex = 1
                    self.updateChart()
                    self.financialTypePicker.isHidden = true
                }),
                UIAction(title: "Location", handler: {_ in
                    self.selectedChartTypeIndex = 2
                    self.updateChart()
                    self.financialTypePicker.isHidden = false
                })
            ]
        )
    }
    
    // MARK: - Setting up month year picker
    
    func setupMonthYearPicker() {
        // Build custom picker and attach to text field
        monthYearPicker = MonthYearPicker(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 250))
        monthYearPicker?.delegate = self

        // Replace keyboard
        datePicker.inputView = monthYearPicker
        datePicker.text = monthYearPicker?.currentDate()
        
        // Add toolbar with Done button
        // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to create a button in the keyboard so that user can pressed it to dismiss the custom keyboard. The output (here) was showing the usage of UIToolbar and how to set it auto dismiss when pressed by using #selector(donePressed) and resignFirstResponser().
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(donePressed))
        toolbar.setItems([doneButton], animated: false)
        datePicker.inputAccessoryView = toolbar
    }

    // Called when Done button pressed
    @objc func donePressed() {
        datePicker.resignFirstResponder()
    }

    // MARK: - MonthYearPickerDelegate
    
    // Called when user selects a new month/year
    func monthYearPicker(month: Int, year: Int) {
        // Format date display text
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let dateComponents = DateComponents(year: year, month: month)
        if let date = Calendar.current.date(from: dateComponents) {
            datePicker.text = formatter.string(from: date)
        }
        updateChart()
    }
}
