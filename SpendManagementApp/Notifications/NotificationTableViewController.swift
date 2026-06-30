//
//  NotificationTableViewController.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 11/10/2025.
//

import UIKit

class NotificationTableViewController: UITableViewController, DatabaseListener {
    
    // Cell identifiers
    let CELL_NOTIFICATION: String = "notificationCell"
    
    // Reference to the database controller
    weak var databaseController: CoreDataController?
    
    // Listener type for database updates
    var listenerType: ListenerType = .notifications
    
    // Notification data
    var allNotifications: [AppNotification] = []
    
    // Grouped notifications by date for table view sections
    var sections: [(title: String, items: [AppNotification])] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController as? CoreDataController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // Used to clear all notifications
    @IBAction func clearButton(_ sender: Any) {
        databaseController?.clearNotification()
    }
    
    // MARK: - Helper method for rebuild notifications based on section (date)
    
    // Rebuilds sections by grouping notifications by date
    func rebuildSections() {
        // Group notifications by date
        let grouped = Dictionary(grouping: allNotifications) { $0.date ?? Date() }

        // Sort the dates in descending order
        let sortedDays = grouped.keys.sorted(by: { date1, date2 in
            return date1 > date2
        })
        
        // Create a list of tuple of (section title, [notifications])
        sections = sortedDays.map { day in
            let title = day.dateString
            
            // Sort notifications with descending order
            let items = (grouped[day] ?? []).sorted {
                if let date1 = $0.date, let date2 = $1.date {
                    return date1 > date2
                }
                return false
            }
            
            return (title, items)
        }

        // Reload table view with updated data
        tableView.reloadData()
    }
    
    // MARK: - DatabaseListener methods
    
    // Execute when notification data changes in Core Data
    func onNotificationsChange(notifications: [AppNotification]) {
        allNotifications = notifications
        rebuildSections()
        tableView.reloadData()
    }
    
    // Unused listener methods
    func onRecordsChange(records: [Record]) { }
    func onCategoriesChange(categories: [Category]) { }
    func onBudgetsChange(budgets: [Budget]) { }
    func onConversionRatesChange(conversionRates: [ConversionRate]) { }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_NOTIFICATION, for: indexPath) as? NotificationTableViewCell
        
        let notification = sections[indexPath.section].items[indexPath.row]
        cell?.configure(notification: notification)
        
        return cell ?? NotificationTableViewCell()
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let notification = allNotifications[indexPath.row]
            databaseController?.deleteNotification(notification: notification)
        }
    }
}
