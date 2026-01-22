//
//  TimerManager.swift
//  UV Tracker
//
//  Created by Dmitriy on 26/12/2025.
//

import Foundation
import Combine
import ActivityKit
import UIKit

@MainActor
class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    @Published var secondsLeft: Int = 0
    @Published var isTimerRunning: Bool = false
    @Published var currentUVIndex: Double = 0
    @Published var finishedSession: FinishedSession?
    
    private var timer: AnyCancellable?
    private var activity: Activity<UVActivityAttributes>?
    private var cancellables = Set<AnyCancellable>()

    private var sessionStartDate: Date?
    private var sessionEndDate: Date?

    struct FinishedSession: Equatable {
        enum EndReason: Equatable {
            case stoppedByUser
            case finished
        }

        let startDate: Date
        let endDate: Date
        let durationSeconds: Int
        let uvIndex: Double
        let reason: EndReason
    }

    private enum StorageKey {
        static let sessionStartDate = "uv_timer_session_start_date"
        static let sessionEndDate = "uv_timer_session_end_date"
        static let uvIndex = "uv_timer_uv_index"
    }
    
    private init() {
        restoreSessionIfNeeded()

        // Keep the countdown accurate after background/close
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.syncWithClock(triggerFinishIfNeeded: true)
                }
            }
            .store(in: &cancellables)
    }
    
    func startTimer(seconds: Int, uvIndex: Double) {
        finishedSession = nil

        let start = Date()
        let end = start.addingTimeInterval(TimeInterval(max(1, seconds)))

        sessionStartDate = start
        sessionEndDate = end
        currentUVIndex = uvIndex
        isTimerRunning = true
        secondsLeft = seconds

        persistSession()
        
        // Start Live Activity
        startLiveActivity(endDate: end, uvIndex: uvIndex)
        
        // Schedule Notification
        NotificationManager.shared.scheduleTimerFinishedNotification(seconds: seconds)
        
        startTicker()
    }
    
    func stopTimer(userInitiated: Bool = true) {
        guard isTimerRunning else { return }

        let end = userInitiated ? Date() : (sessionEndDate ?? Date())
        if let start = sessionStartDate {
            let duration = max(0, Int(end.timeIntervalSince(start)))
            finishedSession = FinishedSession(
                startDate: start,
                endDate: end,
                durationSeconds: duration,
                uvIndex: currentUVIndex,
                reason: userInitiated ? .stoppedByUser : .finished
            )
        }

        isTimerRunning = false
        secondsLeft = 0

        timer?.cancel()
        timer = nil
        
        NotificationManager.shared.cancelAllNotifications()
        clearPersistedSession()
        
        Task {
            await stopLiveActivity()
        }
    }
    
    func addTenMinutes() {
        guard isTimerRunning else { return }
        guard let end = sessionEndDate else { return }

        sessionEndDate = end.addingTimeInterval(600)
        persistSession()

        syncWithClock(triggerFinishIfNeeded: false)
        updateLiveActivity()
        NotificationManager.shared.scheduleTimerFinishedNotification(seconds: secondsLeft)
    }
    
    func syncWithClock(triggerFinishIfNeeded: Bool) {
        guard isTimerRunning else { return }
        guard let end = sessionEndDate else {
            stopTimer(userInitiated: false)
            return
        }

        let remaining = Int(end.timeIntervalSinceNow.rounded(.down))
        if remaining > 0 {
            secondsLeft = remaining
            if secondsLeft % 10 == 0 {
                updateLiveActivity()
            }
        } else if triggerFinishIfNeeded {
            stopTimer(userInitiated: false)
        } else {
            secondsLeft = 0
        }
    }

    private func startTicker() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.syncWithClock(triggerFinishIfNeeded: true)
                }
            }
    }

    private func persistSession() {
        let defaults = UserDefaults.standard
        defaults.set(sessionStartDate, forKey: StorageKey.sessionStartDate)
        defaults.set(sessionEndDate, forKey: StorageKey.sessionEndDate)
        defaults.set(currentUVIndex, forKey: StorageKey.uvIndex)
    }

    private func clearPersistedSession() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: StorageKey.sessionStartDate)
        defaults.removeObject(forKey: StorageKey.sessionEndDate)
        defaults.removeObject(forKey: StorageKey.uvIndex)

        sessionStartDate = nil
        sessionEndDate = nil
    }

    private func restoreSessionIfNeeded() {
        let defaults = UserDefaults.standard
        guard
            let start = defaults.object(forKey: StorageKey.sessionStartDate) as? Date,
            let end = defaults.object(forKey: StorageKey.sessionEndDate) as? Date
        else { return }

        sessionStartDate = start
        sessionEndDate = end
        currentUVIndex = defaults.double(forKey: StorageKey.uvIndex)

        let remaining = Int(end.timeIntervalSinceNow.rounded(.down))
        if remaining > 0 {
            isTimerRunning = true
            secondsLeft = remaining

            // Re-attach to an existing activity if present
            activity = Activity<UVActivityAttributes>.activities.first
            if activity == nil {
                startLiveActivity(endDate: end, uvIndex: currentUVIndex)
            } else {
                updateLiveActivity()
            }

            startTicker()
        } else {
            // Timer finished while the app was closed
            isTimerRunning = false
            secondsLeft = 0

            let duration = max(0, Int(end.timeIntervalSince(start)))
            finishedSession = FinishedSession(
                startDate: start,
                endDate: end,
                durationSeconds: duration,
                uvIndex: currentUVIndex,
                reason: .finished
            )

            clearPersistedSession()

            Task {
                // Try to end any previously running Live Activity
                activity = Activity<UVActivityAttributes>.activities.first
                await stopLiveActivity()
            }
        }
    }
    
    // MARK: - Live Activity
    
    private func startLiveActivity(endDate: Date, uvIndex: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = UVActivityAttributes()
        let initialState = UVActivityAttributes.ContentState(
            endDate: endDate,
            uvIndex: uvIndex
        )
        
        let content = ActivityContent(state: initialState, staleDate: nil)
        
        do {
            activity = try Activity.request(attributes: attributes, content: content)
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func updateLiveActivity() {
        guard let end = sessionEndDate else { return }
        Task {
            let updatedState = UVActivityAttributes.ContentState(
                endDate: end,
                uvIndex: currentUVIndex
            )
            let content = ActivityContent(state: updatedState, staleDate: nil)
            await activity?.update(content)
        }
    }
    
    private func stopLiveActivity() async {
        guard let activity else { return }
        let finalState = UVActivityAttributes.ContentState(
            endDate: Date(),
            uvIndex: currentUVIndex
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        self.activity = nil
    }
}

