//
//  BudgetDetailViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 04/10/2025.
//

import UIKit
import SwiftUI

// Used to communicate selected category data between BudgetDetailViewController and CategoryCheckList
// Allow CategoryCheckList to update the UIKit button
protocol BudgetDetailViewControllerDelegate: AnyObject {
    var selectedCategories: [Category]? { get set }
    func configureCategoryButton()
}

class BudgetDetailViewController: UIViewController, UITextFieldDelegate, BudgetDetailViewControllerDelegate {

    @IBOutlet weak var budgetNameField: UITextField!
    @IBOutlet weak var budgetAmountField: UITextField!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var categoryButton: UIButton!

    // Used to store database controller
    weak var databaseController: DatabaseProtocol?
    
    // .add or .edit mode
    var currentState: ControllerState?
    
    // Stores budget when editing
    var currentBudget: Budget?
    
    // Stores chosen categories for this budget
    var selectedCategories: [Category]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Text field delegate
        budgetAmountField.delegate = self
        
        // UI styling for text fields
        budgetNameField.styled()
        budgetAmountField.styled()
        
        // When start date changes, update end date constraints
        // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to make a live changes when user select the date on the date picker. The output (here) was showing the example of usage of #selector and addTarget to ensure it bind with the func of startDateChanged.
        startDatePicker.addTarget(self, action: #selector(startDateChanged(_:)), for: .valueChanged)
    }
    
    // Configure the screen each time it appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Make sure tab bar is invisible
        self.tabBarController?.tabBar.isHidden = true
        
        if self.isMovingToParent {
            switch currentState {
            case .add:
                configureForAdd()
            case .edit:
                configureForEdit()
            default:
                break
            }
            
            // Update navigation title dynamically
            navigationItem.title = currentState == .add ? "New Budget" : "Budget Details"
        }
    }
    
    // Clear data when leaving screen
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            currentState = nil
            currentBudget = nil
            selectedCategories = nil
        }
    }
    
    // MARK: - Date Change Handlers
    
    // Called whenever user changes start date, this ensures end date always later than start date
    @objc func startDateChanged(_ sender: UIDatePicker) {
        updateDateConstraints()
    }
    
    // MARK: - UpdateDateConstraints method
    
    // Ensure end date cannot be set before start date
    func updateDateConstraints() {
        let start = startDatePicker.date
        endDatePicker.minimumDate = start
    }
    
    // MARK: - Save Button
    
    // Execute when save button pressed
    @IBAction func saveButton(_ sender: Any) {
        // Validate non-empty name
        guard let budgetName = budgetNameField.text, !budgetName.isEmpty else {
            displayMessage(title: "Error", message: "Budget name cannot be empty")
            return
        }
        
        // Validate non-empty amount
        guard let budgetAmount = budgetAmountField.text, !budgetAmount.isEmpty else {
            displayMessage(title: "Error", message: "Budget amount cannot be empty")
            return
        }
        
        // Convert string to Decimal type
        var amount: Decimal = 0
        if let amountDecimal = Decimal(string: budgetAmount) {
            amount = amountDecimal
        }
        
        // Prevent zero-value budgets
        if amount == 0 {
            displayMessage(title: "Error", message: "Amount cannot be 0")
            return
        }
        
        // Ensure category is chosen
        guard let selectedCategories = selectedCategories, !selectedCategories.isEmpty else {
            displayMessage(title: "Error", message: "Category can't be empty")
            return
        }
        
        // Execute correct saving logic
        switch currentState {
        case .add:
            saveNewBudget(amount: amount)
        case .edit:
            updateBudget(amount: amount)
        default:
            break
        }
        
        // Return to previous screen
        navigationController?.popViewController(animated: false)
    }
    
    // MARK: - Category Selection Button
    
    // Opens the CategoryCheckList screen
    @IBAction func categoryButton(_ sender: Any) {
        var checkList = CategoryCheckList()
        checkList.delegate = self
        checkList.currentBudget = currentBudget
        
        // Embed SwiftUI view in UIKit controller
        let host = UIHostingController(rootView: checkList)
        navigationController?.pushViewController(host, animated: true)
    }
    
    // MARK: - BudgetDetailViewControllerDelegate protocol method
    
    // Updates button label according to selected categories
    func configureCategoryButton() {
        if let category = selectedCategories, !category.isEmpty {
            categoryButton.setTitle("Selected: \(category.count)", for: .normal)
        } else {
            categoryButton.setTitle("Choose Category", for: .normal)
        }
    }
    
    // MARK: - Custom methods
    
    // Reset UI fields for adding a new budget
    func configureForAdd() {
        budgetNameField.text = ""
        budgetAmountField.text = ""
        startDatePicker.date = Date()
        endDatePicker.date = Date()
        updateDateConstraints()
        configureCategoryButton()
    }

    // Load existing budget data for editing
    func configureForEdit() {
        if let currentBudget = currentBudget {
            budgetNameField.text = currentBudget.name
            
            // Convert stored Decimal to string
            if let amount = currentBudget.amount {
                budgetAmountField.text = String(format: "%.2f", amount.doubleValue)
            }
            
            if let startDate = currentBudget.startDate {
                startDatePicker.date = startDate
            }
            
            if let endDate = currentBudget.endDate {
                endDatePicker.date = endDate
            }
            updateDateConstraints()
            
            // Extract all linked categories
            var temp: [Category] = []
            for cat in (currentBudget.categories as? Set<Category> ?? []) {
                temp.append(cat)
            }
            selectedCategories = temp
            
            configureCategoryButton()
        }
    }
    
    // MARK: - Core Data Interaction
    
   // Save a new budget
    func saveNewBudget(amount: Decimal) {
        if let selectedCategories = selectedCategories, let name = budgetNameField.text {
            let _ = databaseController?.addBudget(
                name: name,
                amount: amount,
                startDate: startDatePicker.date.startOfDay,
                endDate: endDatePicker.date.startOfDay,
                categories: selectedCategories
            )
        }
    }

    // Update an existing budget
    func updateBudget(amount: Decimal) {
        if let currentBudget = currentBudget, let selectedCategories = selectedCategories, let name = budgetNameField.text {
            let _ = databaseController?.updateBudget(
                budget: currentBudget,
                name: name,
                amount: amount,
                startDate: startDatePicker.date.startOfDay,
                endDate: endDatePicker.date.startOfDay,
                categories: selectedCategories
            )
        }
    }
    
    // MARK: - UITextFieldDelegate method, to handle the string checking of text field
    
    // Validate budgetAmountField to numeric input with up to two decimal places
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let amountText = budgetAmountField.text else {
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
}
