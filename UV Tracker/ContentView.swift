//
//  ContentView.swift
//  UV Tracker
//
//  Created by Dmitriy on 26/12/2025.
//

import SwiftUI
import CoreData
import Combine

struct ContentView: View {
    @ObservedObject private var profileManager = ProfileManager.shared

    var body: some View {
        if profileManager.profile.isOnboardingCompleted {
            MainTabContainerView()
        } else {
            OnboardingView()
        }
    }
}

private enum MainTab: Hashable {
    case home
    case info
    case journal
    case profile
}

private struct MainTabContainerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var timerManager = TimerManager.shared
    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            MainDashboardView()
                .tag(MainTab.home)
                .tabItem { Label("Home", systemImage: "house") }

            InfoView()
                .tag(MainTab.info)
                .tabItem { Label("Info", systemImage: "info.circle") }

            JournalView()
                .tag(MainTab.journal)
                .tabItem { Label("Journal", systemImage: "book") }

            ProfileView()
                .tag(MainTab.profile)
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomTabBar(
                selectedTab: $selectedTab,
                onPlus: { selectedTab = .journal }
            )
        }
        .onReceive(timerManager.$finishedSession.compactMap { $0 }) { session in
            saveSessionToJournal(session)
            timerManager.finishedSession = nil
        }
    }

    private func saveSessionToJournal(_ session: TimerManager.FinishedSession) {
        let entry = UVSession(context: viewContext)
        entry.date = session.startDate
        entry.duration = Int64(session.durationSeconds)
        entry.uvIndex = session.uvIndex
        try? viewContext.save()
    }
}

private struct BottomTabBar: View {
    @Binding var selectedTab: MainTab
    let onPlus: () -> Void

    private let activeColor = Color.primary
    private let inactiveColor = Color.secondary
    private let barHeight: CGFloat = 52

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                tab: .home,
                systemImage: selectedTab == .home ? "house.fill" : "house",
                titleKey: "tab_home"
            )

            tabButton(
                tab: .info,
                systemImage: selectedTab == .info ? "info.circle.fill" : "info.circle",
                titleKey: "tab_info"
            )

            Button(action: onPlus) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "818CD5"))
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                    Image("Group")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .offset(y: -12)

            tabButton(
                tab: .journal,
                systemImage: selectedTab == .journal ? "book.fill" : "book",
                titleKey: "tab_journal"
            )

            tabButton(
                tab: .profile,
                systemImage: selectedTab == .profile ? "person.fill" : "person",
                titleKey: "tab_profile"
            )
        }
        .frame(height: barHeight)
        .background(Color(.systemGroupedBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -8)
        .background(Color(.systemGroupedBackground).ignoresSafeArea(edges: .bottom))
    }

    private func tabButton(tab: MainTab, systemImage: String, titleKey: LocalizedStringKey) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == tab ? activeColor : inactiveColor)
                Text(titleKey)
                    .font(.system(size: 10, weight: .regular, design: .default))
                    .foregroundColor(selectedTab == tab ? activeColor : inactiveColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
