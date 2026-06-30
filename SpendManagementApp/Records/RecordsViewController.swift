//
//  RecordsViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 13/09/2025.
//

import UIKit

class RecordsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DatabaseListener, MonthYearPickerDelegate {

    @IBOutlet weak var recordsTable: UITableView!
    @IBOutlet weak var incomeLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var expenseLabel: UILabel!
    @IBOutlet weak var datePicker: UITextField!
    @IBOutlet weak var currentBalanceLabel: UILabel!
    
    // Constant
    let ROW_HEIGHT: CGFloat = 70
    let CELL_RECORD: String = "recordCell"
    
    // Used to store all records that needed to be displayed
    var allRecords: [Record] = []
    
    // Listener type for database updates
    var listenerType: ListenerType = .records
    
    // Used to store database controller
    weak var databaseController: CoreDataController?
    
    // Custom month and year picker
    var monthYearPicker: MonthYearPicker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up table view with delegate and data source
        recordsTable.delegate = self
        recordsTable.dataSource = self
        
        // Apply styling for date picker
        datePicker.styled()
        
        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController as? CoreDataController
        
        // If current balance is not set initially, force user to input it first
        if databaseController?.initialCurrentBalance == false {
            let vc = storyboard?.instantiateViewController(withIdentifier: "currentBalanceScene") as! CurrentBalanceViewController
            vc.modalPresentationStyle = .fullScreen
            vc.isModalInPresentation = true
            present(vc, animated: true)
        }
        
        // Set up month and year picker
        setupMonthYearPicker()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        // Update balance label
        setupCurrentBalance()
        
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // MARK: - Custom methods
    
    // Update the current balance label using database value
    func setupCurrentBalance() {
        let currentBalance = Decimal(databaseController?.currentBalance ?? 0.0)
        let (formattedCurrentBalance, _) =  currentBalance.formatted(type: FinancialType.unknown)
        currentBalanceLabel.text = formattedCurrentBalance
    }
    
    // Calculate and update total income, expense, and overall total
    func updateSummaryLabels() {
        var totalIncome: Decimal = 0
        var totalExpense: Decimal = 0
        
        // Loop through all records for selected month
        for record in allRecords {
            if let amount = record.amount as? Decimal, let rate = databaseController?.getConversionRate(from: record.conversionCode ?? "AUD").rate as? Decimal {
                
                // Convert to base currency and sum by type
                if record.categories?.financialType == .income {
                    totalIncome += (amount / rate)
                } else {
                    totalExpense += (amount / rate)
                }
            }
        }
        
        // Update income and expense labels
        let (income, _) = totalIncome.formatted(type: .income)
        incomeLabel.text = income

        let (expense, _) = totalExpense.formatted(type: .expense)
        expenseLabel.text = expense

        // Calculate overall total and update color (green/red)
        var total: Decimal = totalIncome - totalExpense
        if total != 0 {
            let sign: FinancialType = total > 0 ? .income : .expense
            total = abs(total)
            let (totalString, color) = total.formatted(type: sign)
            totalLabel.text = totalString
            totalLabel.textColor = color
        } else {
            totalLabel.text = "0.00"
            totalLabel.textColor = .secondaryLabel
        }
    }
    
    // MARK: - tableView methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allRecords.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_RECORD, for: indexPath) as? RecordTableViewCell
        let record = allRecords[indexPath.row]
        cell?.configure(record: record)
        return cell ?? RecordTableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ROW_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let record = allRecords[indexPath.row]
            databaseController?.deleteRecord(record: record)
            setupCurrentBalance()
        }
    }
    
    // MARK: - DatabaseListener
    
    // When database record changes, refresh records and update summary
    func onRecordsChange(records: [Record]) {
        let date = monthYearToInts(datePicker.text!)
        allRecords = databaseController!.fetchRecordsBasedOnMonthAndYear(month: date!.month, year: date!.year)
        updateSummaryLabels()
        recordsTable.reloadData()
    }
    
    // Unused listener methods
    func onCategoriesChange(categories: [Category]) { }
    func onBudgetsChange(budgets: [Budget]) { }
    func onNotificationsChange(notifications: [AppNotification]) { }
    func onConversionRatesChange(conversionRates: [ConversionRate]) { }
    
    // MARK: - Month and Year Picker
        
    // Set up custom month-year picker and toolbar
    func setupMonthYearPicker() {
        monthYearPicker = MonthYearPicker(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 250))
        monthYearPicker?.delegate = self

        // Replace normal keyboard with picker
        datePicker.inputView = monthYearPicker
        datePicker.text = monthYearPicker?.currentDate()
        
        // Add toolbar with "Done" button
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
        
        // Fetch and reload records for that month
        allRecords = databaseController!.fetchRecordsBasedOnMonthAndYear(month: month, year: year)
        recordsTable.reloadData()
        updateSummaryLabels()
    }

    // MARK: - Navigation

    // Prepare destination controller for add/edit record
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! RecordDetailViewController
        if segue.identifier == "editRecordSegue" {
            dest.currentState = .edit
            if let cell = sender as? UITableViewCell, let indexPath = recordsTable.indexPath(for: cell) {
                dest.currentRecord = allRecords[indexPath.row]
            }
        } else {
            dest.currentState = .add
        }
    }
}
