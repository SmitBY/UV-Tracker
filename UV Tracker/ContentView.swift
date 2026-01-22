//
//  ContentView.swift
//  UV Tracker
//
//  Created by Dmitriy on 26/12/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @ObservedObject private var profileManager = ProfileManager.shared

    var body: some View {
        if profileManager.profile.isOnboardingCompleted {
            MainDashboardView()
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
