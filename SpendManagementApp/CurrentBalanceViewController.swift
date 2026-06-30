//
//  CurrentBalanceViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 11/10/2025.
//

import UIKit

class CurrentBalanceViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var currentBalanceField: UITextField!
    
    // Used to store database controller
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Assign text field delegate for input validation
        currentBalanceField.delegate = self
        
        // Apply UI styling
        currentBalanceField.styled()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load and display the current balance
        currentBalanceField.text = String(format: "%.2f", databaseController?.currentBalance ?? 0.0)
    }
    
    // Called when save button pressed
    @IBAction func saveButton(_ sender: Any) {
        // Run if this is the first time setting balance
        if databaseController?.initialCurrentBalance == false {
            databaseController?.initialCurrentBalance = true
        }
        
        // Save the balance input
        databaseController?.currentBalance = Double(currentBalanceField.text ?? "") ?? 0.0
        
        // Close view controller
        if let nav = navigationController {
            nav.popViewController(animated: false)
        } else {
            dismiss(animated: true)
        }
    }
    
    // MARK: - UITextFieldDelegate method, to handle the string checking of text field
    
    // Validate currentBalanceField to numeric input with up to two decimal places
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let amountText = currentBalanceField.text else {
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
