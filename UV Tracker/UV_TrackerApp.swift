//
//  UV_TrackerApp.swift
//  UV Tracker
//
//  Created by Dmitriy on 26/12/2025.
//

import SwiftUI
import CoreData

@main
struct UV_TrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
