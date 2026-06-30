//
//  CategoryDetailViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 20/09/2025.
//

import UIKit

class CategoryDetailViewController: UIViewController {

    // Outlets linked to storyboard UI
    @IBOutlet weak var financialTypeSegment: UISegmentedControl!
    @IBOutlet weak var nameField: UITextField!
    
    // Database reference
    weak var databaseController: DatabaseProtocol?
    
    // Used to track whether user is adding or editing a category
    var currentState: ControllerState?
    
    // Holds the current category if editing
    var currentCategory: Category?
    
    // Preselected segment index
    var selectedFinancialType: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Apply consistent styling to text field
        nameField.styled()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Configure page depending on Add or Edit mode
        switch currentState {
        case .add:
            configureForAdd()
        case .edit:
            configureForEdit()
        default:
            break
        }
        
        // Set financial type segment and navigation title
        financialTypeSegment.selectedSegmentIndex = selectedFinancialType ?? 0
        navigationItem.title = currentState == .add ? "New Category" : "Category Details"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentState = nil
        currentCategory = nil
    }
    
    // Called when Save button is tapped
    @IBAction func saveButton(_ sender: Any) {
        // Ensure name is not empty
        guard let nameText = nameField.text, !nameText.isEmpty else {
            displayMessage(title: "Error", message: "Category name cannot be empty")
            return
        }
        
        // Save or update depending on mode
        switch currentState {
        case .add:
            saveNewCategory(name: nameText)
        case .edit:
            updateCategory(name: nameText)
        default:
            break
        }
        
        // Return to previous screen
        navigationController?.popViewController(animated: false)
    }
    
    // MARK: - Custom methods
    
    // Reset fields for adding new category
    func configureForAdd() {
        financialTypeSegment.selectedSegmentIndex = 0
        nameField.text = ""
    }

    // Load existing category data for editing
    func configureForEdit() {
        if let currentCategory = currentCategory{
            financialTypeSegment.selectedSegmentIndex = Int(currentCategory.financialType.rawValue)
            nameField.text = currentCategory.name
        }
    }
    
    // Add new category to database
    func saveNewCategory(name: String) {
        let category = databaseController?.addCategory(
            name: name,
            type: FinancialType(rawValue: Int32(financialTypeSegment.selectedSegmentIndex)) ?? .unknown
        )
        
        // If category name already exists, show error message
        if category == nil {
            displayMessage(title: "Error", message: "This category name already exists")
        }
    }

    // Update existing category details in database
    func updateCategory(name: String) {
        let category = databaseController?.updateCategory(
            category: currentCategory!,
            name: name,
            type: FinancialType(rawValue: Int32(financialTypeSegment.selectedSegmentIndex)) ?? .unknown
        )
        
        // If category name already exists, show error message
        if category == nil {
            displayMessage(title: "Error", message: "This category name already exists")
        }
    }
}
