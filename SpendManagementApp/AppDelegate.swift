//
//  AppDelegate.swift
//  SpendManagementApp
//
//  Created by Zi You Lim on 11/09/2025.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var databaseController: DatabaseProtocol?
    var notificationsEnabled = false
    
    static let NOTIFICATION_IDENTIFIER = "edu.monash.fit3178.spendmanagementapp.notification"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        databaseController = CoreDataController()
        
        UNUserNotificationCenter.current().delegate = self
        
        Task {
            let notificationCenter = UNUserNotificationCenter.current()
            let notificationSettings = await notificationCenter.notificationSettings()
            if notificationSettings.authorizationStatus == .notDetermined {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert])
                self.notificationsEnabled = granted
            }
            else if notificationSettings.authorizationStatus == .authorized {
                self.notificationsEnabled = true
            }
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        
        return [.banner]
    }
}
