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
    @AppStorage("app_language") private var appLanguage: String = "system"
    
    private var selectedLocale: Locale {
        appLanguage == "system" ? .autoupdatingCurrent : Locale(identifier: appLanguage)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.locale, selectedLocale)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
