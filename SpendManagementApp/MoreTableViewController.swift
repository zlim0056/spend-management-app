//
//  MoreTableViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 02/11/2025.
//

import UIKit

class MoreTableViewController: UITableViewController {
    
    // Used to store database controller
    weak var databaseController: CoreDataController?
    
    // Section constants
    let SECTION_MORE = 0
    let SECTION_CURRENCIES = 1
    let SECTION_ABOUT = 2
    
    // Cell identifiers
    let CELL_MORE = "moreCell"
    let CELL_CURRENCIES = "currenciesCell"
    let CELL_ABOUT = "aboutPageCell"
    
    // Row constants for section "More"
    let NOTIFICATION_ROW = 0
    let CURRENT_BALANCE_ROW = 1
    let CATEGORIES_ROW = 2
    
    // Row constants for section "Currencies"
    let MAIN_CURRENCY_ROW = 0
    let SUB_CURRENCY_ROW = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController as? CoreDataController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table view data source

    // Number of sections: “More”, “Currencies”, “About”
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    // Number of rows per section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_MORE:
            return 3 // Notifications, Current Balance, Categories
        case SECTION_CURRENCIES:
            return 2 // Main Currency, Sub Currency
        case SECTION_ABOUT:
            return 1 // About
        default:
            return 0
        }
    }

    // Configure each cell based on section and row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.section == SECTION_MORE {
            cell = tableView.dequeueReusableCell(withIdentifier: CELL_MORE, for: indexPath)
            switch indexPath.row {
            case NOTIFICATION_ROW:
                cell.textLabel?.text = "Notifications"
            case CURRENT_BALANCE_ROW:
                cell.textLabel?.text = "Current Balance"
            case CATEGORIES_ROW:
                cell.textLabel?.text = "Categories"
            default:
                break
            }
        } else if indexPath.section == SECTION_CURRENCIES {
            cell = tableView.dequeueReusableCell(withIdentifier: CELL_CURRENCIES, for: indexPath)
            switch indexPath.row {
            case MAIN_CURRENCY_ROW:
                cell.textLabel?.text = "Main Currency"
                cell.detailTextLabel?.text = databaseController?.currencyBaseCode
            case SUB_CURRENCY_ROW:
                cell.textLabel?.text = "Sub Currency"
                cell.detailTextLabel?.text = String(databaseController?.countSubCurrencies() ?? 0)
            default:
                break
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: CELL_ABOUT, for: indexPath)
            cell.textLabel?.text = "About"
        }
        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_MORE {
            switch indexPath.row {
            case NOTIFICATION_ROW:
                if let vc = storyboard?.instantiateViewController(withIdentifier: "notificationScene") {
                    navigationController?.pushViewController(vc, animated: true)
                }
            case CURRENT_BALANCE_ROW:
                if let vc = storyboard?.instantiateViewController(withIdentifier: "currentBalanceScene") {
                    navigationController?.pushViewController(vc, animated: true)
                }
            case CATEGORIES_ROW:
                if let vc = storyboard?.instantiateViewController(withIdentifier: "categoriesScene") {
                    navigationController?.pushViewController(vc, animated: true)
                }
            default:
                break
            }
        } else if indexPath.section == SECTION_CURRENCIES {
            switch indexPath.row {
            case MAIN_CURRENCY_ROW:
                if let vc = storyboard?.instantiateViewController(withIdentifier: "selectCurrencyScene") as? CurrenciesTableViewController {
                    vc.currentState = .main
                    navigationController?.pushViewController(vc, animated: true)
                }
            case SUB_CURRENCY_ROW:
                if let vc = storyboard?.instantiateViewController(withIdentifier: "subCurrencyScene") {
                    navigationController?.pushViewController(vc, animated: true)
                }
            default:
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == SECTION_CURRENCIES ? "Currencies" : ""
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
