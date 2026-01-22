//
//  JournalView.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import SwiftUI
import CoreData

struct JournalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UVSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<UVSession>
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(alignment: .leading) {
                Text("tab_journal")
                    .font(.system(size: 32, weight: .bold))
                    .kerning(-1)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top)
                
                if sessions.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "calendar")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("journal_empty_state")
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    List {
                        ForEach(sessions) { session in
                            SessionRow(session: session)
                        }
                        .onDelete(perform: deleteSessions)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            offsets.map { sessions[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct SessionRow: View {
    let session: UVSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.headline)
                Text("UV Index: \(session.uvIndex, specifier: "%.1f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("\(session.duration / 60)m")
                .font(.title3.bold())
                .foregroundColor(Color(hex: "818CD5"))
        }
        .padding(.vertical, 8)
        .listRowBackground(Color(.secondarySystemGroupedBackground))
    }
}
