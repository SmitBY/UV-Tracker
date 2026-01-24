//
//  NotificationManager.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private let timerFinishedNotificationId = "TIMER_FINISHED_NOTIFICATION"
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleTimerFinishedNotification(seconds: Int, sound: TimerNotificationSound) {
        cancelAllNotifications()
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification_title")
        content.body = String(localized: "notification_body")
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        switch sound {
        case .default:
            content.sound = .default
        case .ringtone:
            if #available(iOS 15.0, *) {
                content.sound = .defaultRingtone
            } else {
                content.sound = .default
            }
        case .mute:
            content.sound = nil
        }
        
        // Add action for +10 min
        let addTenAction = UNNotificationAction(identifier: "ADD_TEN_MIN", title: String(localized: "add_10_min"), options: .foreground)
        let category = UNNotificationCategory(identifier: "TIMER_FINISHED", actions: [addTenAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "TIMER_FINISHED"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
        let request = UNNotificationRequest(identifier: timerFinishedNotificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [timerFinishedNotificationId])
        center.removeDeliveredNotifications(withIdentifiers: [timerFinishedNotificationId])
    }
    
    // Present notification (with sound) while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "ADD_TEN_MIN" {
            DispatchQueue.main.async {
                TimerManager.shared.addTenMinutes()
            }
        }
        completionHandler()
    }
}


