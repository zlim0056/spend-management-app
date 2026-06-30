//
//  CurrenciesTableViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 12/10/2025.
//

import UIKit

// Represents the current purpose of the currency selection screen
enum CurrencySelectionState {
    case main   // Selecting a new main/base currency
    case sub    // Selecting currencies to use as sub currencies
    case choose // Selecting a conversion rate for record entry
}

class CurrenciesTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {
    
    // API key for currency conversion service
    let API_KEY: String = "01194c917f3ab99c052b3b74"
    
    // Cell identifiers
    let CELL_CURRENCY: String = "currencyCell"
    
    // Listener type for database updates
    var listenerType: ListenerType = .conversionRates
    
    // Database controller reference
    weak var databaseController: CoreDataController?
    
    // Currency conversion data
    var allRates: [ConversionRate] = []
    var filteredRates: [ConversionRate] = []
    
    // Loading indicator for fetching data
    var indicator = UIActivityIndicatorView()
    
    // Current state of this view (main/sub/choose)
    var currentState: CurrencySelectionState?
    
    // Delegate to pass selected conversion rate back to RecordDetailViewController
    var delegate: RecordDetailConversionRate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController as? CoreDataController
        
        // Set up search controller for searching currency code or name
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search currency code or name"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Set up and center the loading indicator
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        // If no conversion rates stored, load from API
        if databaseController?.fetchAllConvensionRates().count ?? 0 <= 1 {
            Task {
                await loadRates()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start listening for database updates
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
        
        // Reset state when navigating back
        if self.isMovingFromParent {
            currentState = nil
        }
    }
    
    // Called when user taps refresh button
    @IBAction func refreshButton(_ sender: Any) {
        Task {
            await loadRates()
        }
    }
    
    // MARK: - DatabaseListener methods
    
    // Called when conversion rates in database are updated
    func onConversionRatesChange(conversionRates: [ConversionRate]) {
        allRates = conversionRates
        
        // Filter list based on current state
        if currentState == .sub {
            filteredRates = allRates.filter { !$0.isSub && $0.code != databaseController?.currencyBaseCode }
        } else if currentState == .main {
            filteredRates = allRates.filter { $0.code != databaseController?.currencyBaseCode }
        } else {
            filteredRates = allRates.filter { $0.isSub || $0.code == databaseController?.currencyBaseCode }
        }
        tableView.reloadData()
    }
    
    // Unused listener methods
    func onRecordsChange(records: [Record]) { }
    func onCategoriesChange(categories: [Category]) { }
    func onBudgetsChange(budgets: [Budget]) { }
    func onNotificationsChange(notifications: [AppNotification]) { }
    
    // MARK: - API Call for Conversion Rates
        
    // Load conversion rates from API and save to database
    func loadRates() async {
        indicator.startAnimating()
        
        var searchURLComponents = URLComponents()
        searchURLComponents.scheme = "https"
        searchURLComponents.host = "v6.exchangerate-api.com"
        searchURLComponents.path = "/v6/\(API_KEY)/latest/\(databaseController?.currencyBaseCode ?? "AUD")"
        
        guard let requestURL = searchURLComponents.url else {
            print("Invalid URL.")
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // Keep track of sub currencies before refreshing
            let subCurrencies = allRates.filter { $0.isSub }.map { $0.code! }
            
            // Clear old data
            databaseController?.clearConversionRate()
            
            // Fetch API data
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            indicator.stopAnimating()
            
            // Decode JSON into ConversionRatesData object
            let decoder = JSONDecoder()
            let conversionRatesData = try decoder.decode(ConversionRatesData.self, from: data)
            
            // Add each rate to Core Data
            if let crd = conversionRatesData.conversionRates {
                for cr in crd {
                    let _ = databaseController?.addConversionRate(code: cr.key, rate: cr.value)
                }
                // Saved entries and restore sub currencies
                databaseController?.cleanup()
                databaseController?.setupSubCurrencies(subCurrencies: subCurrencies)
            }
            
        } catch let error {
            print(error)
        }
    }
    
    // MARK: - UISearchResultsUpdating method
    
    // Called when search bar text changes
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            // Filter by currency code or localized currency name
            filteredRates = allRates.filter({ rate in
                if let code = rate.code {
                    // Search for the country code
                    if code.lowercased().contains(searchText) {
                        return true
                    }
                    
                    // Search for the country name
                    // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to convert a country code to country name. The output (here) was showing the usage of Locale.current.localizedString(forCurrencyCode: CountryCode) and it will return a country name based on the country code.
                    let name = Locale.current.localizedString(forCurrencyCode: code)?.lowercased() ?? "Failed to get country name"
                    return name.contains(searchText)
                }
                return false
            })
        } else {
            // If no text entered, show all
            filteredRates = allRates
        }
        
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Number of rows equals filtered rate count
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredRates.count
    }

    // Configure each cell to show currency name and conversion rate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_CURRENCY, for: indexPath)

        let item = filteredRates[indexPath.row]
        if let code = item.code, let rate = item.rate {
            // Get localized currency name
            // I acknowledge the use of ChatGPT (https://chatgpt.com/) to learn how to convert a country code to country name. The output (here) was showing the usage of Locale.current.localizedString(forCurrencyCode: CountryCode) and it will return a country name based on the country code.
            let currencyName = Locale.current.localizedString(forCurrencyCode: code) ?? "Failed to get country name"
            
            // Display both code and name
            cell.textLabel?.text = currencyName.isEmpty ? code : "\(code) - \(currencyName)"
            
            // Show conversion rate
            cell.detailTextLabel?.text = "\(databaseController?.currencyBaseCode ?? "AUD") 1.00 = \(code) \(rate)"
        }
            
        return cell
    }
    
    // Handle row selection depending on current state
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let state = currentState {
            let item = filteredRates[indexPath.row]
            
            // Selecting new main currency
            if state == .main {
                let alertController = UIAlertController(title: "Changing main currency", message: "Changing main currency will clear all records, sub currencies, budgets and notifications, and reset current balance value. Are you sure?", preferredStyle: .alert)
                
                // Cancel button
                alertController.addAction(UIAlertAction(title: "No", style: .destructive, handler: { _ in
                    self.tableView.deselectRow(at: indexPath, animated: false)
                }))
                
                // Confirm button
                alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                    self.databaseController?.clearRecord()
                    self.databaseController?.clearSubCurrency()
                    self.databaseController?.clearBudget()
                    self.databaseController?.clearNotification()
                    self.databaseController?.clearConversionRate()
                    self.databaseController?.currencyBaseCode = item.code ?? "Failed to get country code"
                    Task {
                        await self.loadRates()
                    }
                    self.navigationController?.popViewController(animated: false)
                }))
                
                self.present(alertController, animated: true, completion: nil)
            
            // Adding a sub currency
            } else if state == .sub {
                let _ = databaseController?.addSubCurrency(convensionRate: item)
            
            // Selecting conversion for a record
            } else {
                delegate?.selectedConversion = item
                delegate?.configureConversionButtonAndLabel()
            }
            navigationController?.popViewController(animated: false)
        }
    }

    // Disable table editing
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
