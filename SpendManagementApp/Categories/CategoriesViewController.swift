//
//  CategoriesViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 19/09/2025.
//

import UIKit

class CategoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, DatabaseListener {
    
    // Outlets linked to storyboard UI
    @IBOutlet weak var categoryTypeSegment: UISegmentedControl!
    @IBOutlet weak var categoryTableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    // Cell identifiers
    let CELL_CATEGORIES: String = "categoriesCell"
    
    // Categories data
    var allCategories: [Category] = []
    var filteredCategories: [Category] = []
    var currentCategories: [Category] = []
    
    // Listener type for Core Data updates
    var listenerType: ListenerType = .categories
    
    // References to database and delegate
    weak var databaseController: DatabaseProtocol?
    weak var delegate: RecordDetailCategory?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup table view delegates
        categoryTableView.delegate = self
        categoryTableView.dataSource = self
        
        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Setup search bar for filtering categories
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search All Categories"
        navigationItem.searchController = searchController
        
        // Ensures that search bar does not remain on other screens
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // Call when user switches between Income / Expense segment
    @IBAction func categorySegmentPressed(_ sender: Any) {
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    // MARK: - Custom methods
    
    // Refresh the table based on selected segment type
    func refreshTable() {
        let type: FinancialType = FinancialType(rawValue: Int32(categoryTypeSegment.selectedSegmentIndex)) ?? .unknown
        currentCategories = filteredCategories.filter { $0.financialType == type }
        categoryTableView.reloadData()
    }
    
    // MARK: - DatabaseListener methods
    
    // When the category changes in database, update the displayed results
    func onCategoriesChange(categories: [Category]) {
        allCategories = categories
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    // Unused listener methods
    func onRecordsChange(records: [Record]) { }
    func onBudgetsChange(budgets: [Budget]) { }
    func onNotificationsChange(notifications: [AppNotification]) { }
    func onConversionRatesChange(conversionRates: [ConversionRate]) { }
    
    // MARK: - TableView methods
    
    // Number of rows = number of categories in current segment
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentCategories.count
    }
    
    // Configure each cell with category name
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_CATEGORIES, for: indexPath)
        let category = currentCategories[indexPath.row]
        cell.textLabel?.text = category.name
        return cell
    }
    
    // Allow deletion
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Handle deletion of a category
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let category = currentCategories[indexPath.row]
            databaseController?.deleteCategory(category: category)
        }
    }
    
    // When info button is tapped, open edit screen for that category
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        performSegue(withIdentifier: "editCategorySegue", sender: indexPath)
    }
    
    // When a row is selected, return the category to RecordDetailViewController screen
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = delegate {
            let category: Category = currentCategories[indexPath.row]
            delegate.selectedCategory = category
            delegate.configureCategoryButton()
            navigationController?.popViewController(animated: false)
        }
    }

    // MARK: - Navigation

    // Prepare for transition to CategoryDetailViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! CategoryDetailViewController
        if segue.identifier == "editCategorySegue" {
            // Edit existing category
            dest.currentState = .edit
            if let indexPath = sender as? IndexPath {
                dest.currentCategory = currentCategories[indexPath.row]
            }
        } else {
            // Add new category
            dest.currentState = .add
            dest.selectedFinancialType = categoryTypeSegment.selectedSegmentIndex
        }
    }
    
    // Prevent automatic segue
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier == "editCategorySegue" ? false : true
    }
    
    // MARK: - UISearchResultsUpdating method
    
    // Update search results when user types in the search bar
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        // Filter categories by search text
        if searchText.count > 0 {
            filteredCategories = allCategories.filter({ (category: Category) -> Bool in
                return (category.name?.lowercased().contains(searchText) ?? false)
            })
        } else {
            filteredCategories = allCategories
        }
        
        // Refresh the table to show filtered results
        refreshTable()
    }
}
