//
//  BudgetsViewTableViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 04/10/2025.
//

import UIKit

class BudgetsViewTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {
    
    // Section identifiers
    let SECTION_ACTIVE = 0
    let SECTION_NOT_STARTED = 1
    let SECTION_EXPIRED = 2
    
    // Cell identifiers
    let CELL_ACTIVE = "activeBudgetCell"
    let CELL_NOT_STARTED = "notStartedBudgetCell"
    let CELL_EXPIRED = "expiredBudgetCell"
    
    // Listener type for database updates
    var listenerType: ListenerType = .budgets
    
    // Budget data
    var allBudgets: [Budget] = []
    var filteredBudgets: [Budget] = []
    var expiredBudgets: [Budget] = []
    var activeBudgets: [Budget] = []
    var notStartedBudgets: [Budget] = []
    
    // Database controller reference
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Setup search controller for searching budgets by name
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search All Budgets"
        navigationItem.searchController = searchController
        
        // Ensure navigation presentation context is defined
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // MARK: - DatabaseListener methods
    
    // Call when the budget changes in database
    func onBudgetsChange(budgets: [Budget]) {
        allBudgets = budgets
        updateSearchResults(for: navigationItem.searchController!)
    }

    // Unused listener methods
    func onRecordsChange(records: [Record]) { }
    func onCategoriesChange(categories: [Category]) { }
    func onNotificationsChange(notifications: [AppNotification]) { }
    func onConversionRatesChange(conversionRates: [ConversionRate]) { }
    
    // MARK: - Table view data source

    // There are 3 sections which are Active, Not Started, Expired
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    // Number of rows depends on section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_ACTIVE:
            return activeBudgets.count
        case SECTION_NOT_STARTED:
            return notStartedBudgets.count
        case SECTION_EXPIRED:
            return expiredBudgets.count
        default:
            return 0
        }
    }

    // Configure cell for each budget section
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let budget: Budget
        let identifier: String
        
        switch indexPath.section {
        case SECTION_ACTIVE:
            identifier = CELL_ACTIVE
            budget = activeBudgets[indexPath.row]
        case SECTION_NOT_STARTED:
            identifier = CELL_NOT_STARTED
            budget = notStartedBudgets[indexPath.row]
        default:
            identifier = CELL_EXPIRED
            budget = expiredBudgets[indexPath.row]
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? BudgetTableViewCell
        cell?.configure(budget: budget)
        return cell ?? BudgetTableViewCell()
    }

    // Allow user to delete a budget
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Handle deletion of a budget
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let budget: Budget
            
            switch indexPath.section {
            case SECTION_ACTIVE:
                budget = activeBudgets[indexPath.row]
            case SECTION_NOT_STARTED:
                budget = notStartedBudgets[indexPath.row]
            case SECTION_EXPIRED:
                budget = expiredBudgets[indexPath.row]
            default:
                return
            }
            
            databaseController?.deleteBudget(budget: budget)
        }
    }
    
    // Set section titles
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case SECTION_ACTIVE:
            return "ACTIVE BUDGETS"
        case SECTION_NOT_STARTED:
            return "NOT STARTED BUDGETS"
        case SECTION_EXPIRED:
            return "EXPIRED BUDGETS"
        default:
            return ""
        }
    }

    // MARK: - Navigation

    // Prepare for segue to BudgetDetailViewController (add or edit)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! BudgetDetailViewController
        if segue.identifier == "editBudgetSegue" {
            dest.currentState = .edit
            if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
                switch indexPath.section {
                case SECTION_ACTIVE:
                    dest.currentBudget = activeBudgets[indexPath.row]
                case SECTION_NOT_STARTED:
                    dest.currentBudget = notStartedBudgets[indexPath.row]
                case SECTION_EXPIRED:
                    dest.currentBudget = expiredBudgets[indexPath.row]
                default:
                    return
                }
            }
        } else {
            dest.currentState = .add
        }
    }
    
    // MARK: - UISearchResultsUpdating method
    
    // Called whenever the search bar text changes
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        // Filter budgets by name text
        if searchText.count > 0 {
            filteredBudgets = allBudgets.filter({ (budget: Budget) -> Bool in
                return (budget.name?.lowercased().contains(searchText) ?? false)
            })
        } else {
            filteredBudgets = allBudgets
        }
        
        // Filtered budgets to different category (Active, Not Started, Expired)
        let today = Date().startOfDay
        activeBudgets = filteredBudgets.filter { ($0.startDate ?? Date()) <= today && today <= ($0.endDate ?? Date()) }
        notStartedBudgets = filteredBudgets.filter { $0.startDate ?? Date() > today }
        expiredBudgets = filteredBudgets.filter { ($0.endDate ?? Date()) < today }
        
        // Reload the table with updated data
        tableView.reloadData()
    }
}
