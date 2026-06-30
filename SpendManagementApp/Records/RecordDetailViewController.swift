//
//  NewRecordViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 15/09/2025.
//

import UIKit

// Delegate used by CategoryViewController
protocol RecordDetailCategory: AnyObject {
    var selectedCategory: Category? { get set }
    func configureCategoryButton()
}

// Delegate used by LocationSelectionViewController
protocol RecordDetailLocation: AnyObject {
    var selectedLocation: String? { get set }
    func configureLocationButton()
}

// Delegate used by CurrenciesTableViewController
protocol RecordDetailConversionRate: AnyObject {
    var selectedConversion: ConversionRate? { get set }
    func configureConversionButtonAndLabel()
}

class RecordDetailViewController: UIViewController, UITextFieldDelegate, RecordDetailCategory, RecordDetailLocation, RecordDetailConversionRate {
    
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var baseCurrencyButton: UIButton!
    @IBOutlet weak var conversionRateLabel: UILabel!
    @IBOutlet weak var dateField: UIDatePicker!
    @IBOutlet weak var noteField: UITextView!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    
    // Used to store the database controller from Core Date
    weak var databaseController: CoreDataController?
    
    // .add or .edit mode
    var currentState: ControllerState?
    
    // Stores record, category, location, conversion for adding and editing
    var currentRecord: Record?
    var selectedCategory: Category?
    var selectedLocation: String?
    var selectedConversion: ConversionRate?
    
    // Save button tapped
    @IBAction func saveButton(_ sender: Any) {
        // Validate amount
        guard let amountText = amountField.text, !amountText.isEmpty else {
            displayMessage(title: "Error", message: "Amount cannot be empty")
            return
        }
        
        // Validate category
        guard let _ = selectedCategory else {
            displayMessage(title: "Error", message: "Category cannot be empty")
            return
        }
        
        // Parse amount as Decimal
        var amount: Decimal = 0
        if let amountDecimal = Decimal(string: amountText) {
            amount = amountDecimal
        }
        
        // Validate zero amount
        if amount == 0 {
            displayMessage(title: "Error", message: "Amount cannot be 0")
            return
        }
        
        // Perform add or edit based on currentState
        switch currentState {
        case .add:
            saveNewRecord(amount: amount)
        case .edit:
            updateRecord(amount: amount)
        default:
            break
        }
        
        navigationController?.popViewController(animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController as? CoreDataController
        
        // Basic styling
        amountField.styled()
        noteField.layer.borderWidth = 1
        noteField.layer.cornerRadius = 8
        noteField.layer.borderColor = UIColor.separator.cgColor
        
        // Delegate
        amountField.delegate = self
        
        // Disallow future dates
        dateField.maximumDate = Date()
        
        // When amount change, update the conversion UI
        // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to make a live changes when user enter amount in the amountField. The output (here) was showing the example of usage of #selector and addTarget to ensure it bind with the func of amountDidChange to make live changes.
        amountField.addTarget(self, action: #selector(amountDidChange), for: .editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true

        if self.isMovingToParent {
            switch currentState {
            case .add:
                // Default to base conversion rate on new record
                selectedConversion = databaseController?.getBaseConversionRate()
                configureForAdd()
            case .edit:
                // Load the conversion used by existing record
                selectedConversion = databaseController?.getConversionRate(from: currentRecord?.conversionCode ?? "AUD")
                configureForEdit()
            default:
                break
            }
            
            navigationItem.title = currentState == .add ? "New Record" : "Record Details"
            configureConversionButtonAndLabel()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            currentState = nil
            currentRecord = nil
            selectedCategory = nil
            selectedLocation = nil
            selectedConversion = nil
        }
    }
    
    // MARK: - Amount Change Handlers
    
    // When amount text changes, recompute conversion UI
    @objc private func amountDidChange() {
        updateConversionUI()
    }
    
    // MARK: - UpdateConversionUI method

    // Update currency button title and conversion label
    func updateConversionUI() {
        // Check whether currencyBaseCode exist
        guard let baseCode = databaseController?.currencyBaseCode else {
            conversionRateLabel.text = ""
            return
        }

        // Check whether any conversionRate selected
        guard let conv = selectedConversion, let code = conv.code, let rateNum = conv.rate else {
            baseCurrencyButton.setTitle(baseCode, for: .normal)
            conversionRateLabel.text = ""
            return
        }

        // Button shows currently selected currency code
        baseCurrencyButton.setTitle(code, for: .normal)

        // If same as base, no conversion string needed
        if code == baseCode {
            conversionRateLabel.text = ""
            return
        }

        // Calculate converted amount (converted = amount / rate)
        let rate = rateNum.decimalValue
        let amount = Decimal(string: amountField.text ?? "") ?? 0
        let converted = amount / rate
        
        // Format numbers nicely
        let formatedConvertedAmount = String(format: "%.2f", NSDecimalNumber(decimal: converted).doubleValue)

        let rateLine = "\(baseCode) 1.00 = \(code) \(rate)"
        let amountLine = "\(baseCode) \(formatedConvertedAmount)"

        conversionRateLabel.text = "\(rateLine)\n\(amountLine)"
    }
    
    // MARK: - Configuration current view controller methods
    
    // Reset fields for adding a new record
    func configureForAdd() {
        amountField.text = ""
        dateField.date = Date()
        noteField.text = ""
        configureLocationButton()
        configureCategoryButton()
        configureConversionButtonAndLabel()
    }

    // Load fields for editing an existing record
    func configureForEdit() {
        if let currentRecord = currentRecord {
            if let amount = currentRecord.amount {
                amountField.text = String(format: "%.2f", amount.doubleValue)
            }
            
            if let date = currentRecord.date {
                dateField.date = date
            }
            
            noteField.text = currentRecord.note
            
            // Category
            selectedCategory = currentRecord.categories
            configureCategoryButton()
            
            // Location
            selectedLocation = currentRecord.location
            configureLocationButton()
            
            // Conversion Rate
            selectedConversion = databaseController?.getConversionRate(from: currentRecord.conversionCode ?? "AUD")
            configureConversionButtonAndLabel()
        }
    }
    
    // MARK: - CoreData methods
    
    // Create a new record
    func saveNewRecord(amount: Decimal) {
        if let selectedCategory = selectedCategory, let selectedConversion = selectedConversion {
            let _ = databaseController?.addRecord(
                date: dateField.date,
                amount: amount,
                location: selectedLocation ?? "Unknown Location",
                note: noteField.text,
                category: selectedCategory,
                conversionCode: selectedConversion.code ?? "AUD"
            )
        }
    }

    // Update an existing record
    func updateRecord(amount: Decimal) {
        if let currentRecord = currentRecord, let cat = currentRecord.categories, let code = currentRecord.conversionCode {
            let _ = databaseController?.updateRecord(
                record: currentRecord,
                date: dateField.date,
                amount: amount,
                location: selectedLocation ?? "Unknown Location",
                note: noteField.text,
                category: cat,
                conversionCode: code
            )
        }
    }
    
    // MARK: - RecordDetailCategory method
    
    // Update category button title
    func configureCategoryButton() {
        if let category = selectedCategory {
            let type: String = category.financialType == .expense ? "Expense" : "Income"
            categoryButton.setTitle("\(type): \(category.name ?? "")", for: .normal)
        } else {
            categoryButton.setTitle("Choose Category", for: .normal)
        }
    }
    
    // MARK: - RecordDetailLocation method
    
    // Update location button configuration
    func configureLocationButton() {
        guard let location = selectedLocation else {
            return
        }
        var config = locationButton.configuration
        config?.title = location != "" ? location : "Choose Location"
        config?.titleLineBreakMode = .byTruncatingTail
        locationButton.configuration = config
    }
    
    // MARK: - RecordDetailConversionRate method
    
    // Update base currency button and label
    func configureConversionButtonAndLabel() {
        guard let currentCR = databaseController?.currencyBaseCode else {
            return
        }

        if let conversionRate = selectedConversion, let code = conversionRate.code {
            baseCurrencyButton.setTitle(conversionRate.code == currentCR ? currentCR : code, for: .normal)
        } else {
            baseCurrencyButton.setTitle(currentCR, for: .normal)
        }

        updateConversionUI()
    }
    
    // MARK: - UITextFieldDelegate method, to handle the string checking of text field
    
    // Validate amountField to numeric input with up to two decimal places
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let amountText = amountField.text else {
            return false
        }
        
        // Convert NSRange to Swift String range
        guard let stringRange = Range(range, in: amountText) else {
            return false
        }
        
        // Preview updated text (after typing/pasting/deleting)
        let updatedText = amountText.replacingCharacters(in: stringRange, with: string)

        // Allow clearing the field completely (so backspacing everything out works)
        if updatedText.isEmpty {
            return true
        }
        
        /*
         Validation rule as a regular expression:
         - ^...$ → must match the entire string
         - ([1-9]\\d*|0) → integer part is either a non-zero digit followed by any digits or a single 0
         - (\\.\\d{0,2})? → optional decimal part: a dot . followed by 0 to 2 digits.
         */
        // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to validate the string by using regex so that user can only enter decimal with 2 decimal or integer or 0. The output (here) was showing the regex string that can used to validate user's input string.
        let regex = "^([1-9]\\d*|0)(\\.\\d{0,2})?$"
        
        // Wrap the regex in a predicate that checks full-string matches
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        
        return predicate.evaluate(with: updatedText)
    }

    // MARK: - Navigation

    // Prepare next view controllers and pass delegates/state
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chooseCategorySegue" {
            let dest = segue.destination as! CategoriesViewController
            dest.delegate = self
        } else if segue.identifier == "chooseLocationSegue" {
            let dest = segue.destination as! LocationSelectionViewController
            dest.delegate = self
        } else if segue.identifier == "chooseCurrenciesSegue" {
            let dest = segue.destination as! CurrenciesTableViewController
            dest.delegate = self
            dest.currentState = .choose
        }
    }
}
