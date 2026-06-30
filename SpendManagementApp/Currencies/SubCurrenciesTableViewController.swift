//
//  SubCurrenciesTableViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 12/10/2025.
//

import UIKit

class SubCurrenciesTableViewController: UITableViewController {
    
    let CELL_SUB_CURRENCIES: String = "subCurrencyCell"
    
    // Database controller reference
    weak var databaseController: CoreDataController?
    
    // Stores all currencies marked as sub currencies
    var allSubCurrencies: [ConversionRate] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController as? CoreDataController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch all sub currencies and reload table
        allSubCurrencies = databaseController?.fetchAllConvensionRates().filter { $0.isSub } ?? []
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Number of rows equals number of sub currencies
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allSubCurrencies.count
    }

    // Configure each cell to display sub currency information
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_SUB_CURRENCIES, for: indexPath)

        let item = allSubCurrencies[indexPath.row]
        
        // Show currency code and name with conversion rate
        if let code = item.code, let rate = item.rate {
            let currencyName = Locale.current.localizedString(forCurrencyCode: code) ?? ""
            cell.textLabel?.text = currencyName.isEmpty ? code : "\(code) - \(currencyName)"
            cell.detailTextLabel?.text = "\(databaseController?.currencyBaseCode ?? "AUD") 1.00 = \(code) \(rate)"
        }

        return cell
    }

    // Allow deletion
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Handle deletion for sub currency
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = allSubCurrencies[indexPath.row]
            databaseController?.deleteSubCurrency(convensionRate: item)
            
            // Reload table to update list
            viewWillAppear(false)
        }
    }

    // MARK: - Navigation

    // Prepare for segue to CurrenciesTableViewController (for selecting new sub currencies)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "subCurrencySegue" {
            let dest = segue.destination as! CurrenciesTableViewController
            dest.currentState = .sub
        }
    }
}
