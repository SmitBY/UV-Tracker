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
    @Published var secondsElapsed: Int = 0
    @Published var isTimerRunning: Bool = false
    @Published var currentUVIndex: Double = 0
    @Published var uvDose: Double = 0
    @Published var finishedSession: FinishedSession?
    
    private var timer: AnyCancellable?
    private var activity: Activity<UVActivityAttributes>?
    private var cancellables = Set<AnyCancellable>()

    private var sessionStartDate: Date?
    private var sessionEndDate: Date?
    
    // Exposure integration:
    // - accumulatedUVIndexSeconds: ∫ UVIndex dt  (UV Index * seconds)
    // - burnLimitUVIndexSeconds: threshold in the same units (plus user-added allowance)
    private var accumulatedUVIndexSeconds: Double = 0
    private var burnLimitUVIndexSeconds: Double = 0
    private var lastDoseUpdateDate: Date?

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
        static let accumulatedUVIndexSeconds = "uv_timer_accumulated_uv_index_seconds"
        static let burnLimitUVIndexSeconds = "uv_timer_burn_limit_uv_index_seconds"
        static let lastDoseUpdateDate = "uv_timer_last_dose_update_date"
    }
    
    private init() {
        // Defer restoration to avoid "Publishing changes from within view updates" 
        // when shared instance is first accessed during a view update (e.g. in @StateObject)
        Task { @MainActor in
            self.restoreSessionIfNeeded()
        }

        // Keep the countdown accurate after background/close
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.syncWithClock(triggerFinishIfNeeded: true)
                }
            }
            .store(in: &cancellables)
        
        // Persist session state when app goes to background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.persistSession()
                }
            }
            .store(in: &cancellables)
    }
    
    func startTimer(seconds: Int, uvIndex: Double, burnLimitUVIndexSeconds: Double? = nil) {
        finishedSession = nil

        let start = Date()
        let end = start.addingTimeInterval(TimeInterval(max(1, seconds)))

        sessionStartDate = start
        sessionEndDate = end
        currentUVIndex = uvIndex
        isTimerRunning = true
        secondsLeft = seconds
        secondsElapsed = 0
        
        // Reset session dose state
        accumulatedUVIndexSeconds = 0
        self.burnLimitUVIndexSeconds = burnLimitUVIndexSeconds ?? defaultBurnLimitUVIndexSeconds(seconds: seconds, uvIndex: uvIndex)
        uvDose = 0
        lastDoseUpdateDate = start

        persistSession()
        
        // Start Live Activity
        startLiveActivity(endDate: end, uvIndex: uvIndex)
        
        // Schedule Notification
        NotificationManager.shared.scheduleTimerFinishedNotification(
            seconds: seconds,
            sound: ProfileManager.shared.profile.timerNotificationSound
        )
        
        startTicker()
    }
    
    func stopTimer(userInitiated: Bool = true) {
        guard isTimerRunning else { return }

        let end = userInitiated ? Date() : (sessionEndDate ?? Date())
        accumulateDose(until: end)
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
        secondsElapsed = 0
        uvDose = 0
        accumulatedUVIndexSeconds = 0
        burnLimitUVIndexSeconds = 0
        lastDoseUpdateDate = nil

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
        let now = Date()
        let effectiveNow = min(now, sessionEndDate ?? now)
        accumulateDose(until: effectiveNow)
        
        // Add "10 minutes worth of exposure" at the current UV index.
        // This keeps the extra time consistent even if UV changes later.
        if currentUVIndex > 0 {
            burnLimitUVIndexSeconds += currentUVIndex * 600.0
            let remaining = calculateRemainingSeconds(forUVIndex: currentUVIndex)
            if remaining <= 0 {
                stopTimer(userInitiated: false)
                return
            }
            sessionEndDate = now.addingTimeInterval(TimeInterval(remaining))
            secondsLeft = remaining
        } else if let end = sessionEndDate {
            // Fallback to legacy behavior when UV is 0
            sessionEndDate = end.addingTimeInterval(600)
            secondsLeft = max(0, secondsLeft + 600)
        } else {
            sessionEndDate = now.addingTimeInterval(600)
            secondsLeft = 600
        }
        
        persistSession()
        updateLiveActivity()
        NotificationManager.shared.scheduleTimerFinishedNotification(
            seconds: secondsLeft,
            sound: ProfileManager.shared.profile.timerNotificationSound
        )
    }
    
    func updateSessionUVIndex(_ uvIndex: Double) {
        guard isTimerRunning else { return }
        let now = Date()
        let effectiveNow = min(now, sessionEndDate ?? now)
        accumulateDose(until: effectiveNow)
        
        currentUVIndex = uvIndex
        
        let remaining = calculateRemainingSeconds(forUVIndex: uvIndex)
        if remaining <= 0 {
            stopTimer(userInitiated: false)
            return
        }
        
        sessionEndDate = now.addingTimeInterval(TimeInterval(remaining))
        secondsLeft = remaining
        
        persistSession()
        updateLiveActivity()
        NotificationManager.shared.scheduleTimerFinishedNotification(
            seconds: secondsLeft,
            sound: ProfileManager.shared.profile.timerNotificationSound
        )
    }
    
    func syncWithClock(triggerFinishIfNeeded: Bool) {
        guard isTimerRunning else { return }
        guard let start = sessionStartDate, let end = sessionEndDate else {
            stopTimer(userInitiated: false)
            return
        }

        let now = Date()
        let effectiveNow = min(now, end)
        
        // Integrate dose up to "now" (but never beyond the planned end time)
        accumulateDose(until: effectiveNow)
        
        let elapsed = Int(now.timeIntervalSince(start))
        secondsElapsed = max(0, elapsed)

        let remaining = Int(end.timeIntervalSince(now).rounded(.down))
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
        defaults.set(accumulatedUVIndexSeconds, forKey: StorageKey.accumulatedUVIndexSeconds)
        defaults.set(burnLimitUVIndexSeconds, forKey: StorageKey.burnLimitUVIndexSeconds)
        defaults.set(lastDoseUpdateDate, forKey: StorageKey.lastDoseUpdateDate)
    }

    private func clearPersistedSession() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: StorageKey.sessionStartDate)
        defaults.removeObject(forKey: StorageKey.sessionEndDate)
        defaults.removeObject(forKey: StorageKey.uvIndex)
        defaults.removeObject(forKey: StorageKey.accumulatedUVIndexSeconds)
        defaults.removeObject(forKey: StorageKey.burnLimitUVIndexSeconds)
        defaults.removeObject(forKey: StorageKey.lastDoseUpdateDate)

        sessionStartDate = nil
        sessionEndDate = nil
        accumulatedUVIndexSeconds = 0
        burnLimitUVIndexSeconds = 0
        lastDoseUpdateDate = nil
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
        
        if defaults.object(forKey: StorageKey.accumulatedUVIndexSeconds) != nil {
            accumulatedUVIndexSeconds = defaults.double(forKey: StorageKey.accumulatedUVIndexSeconds)
        } else {
            // Backward-compatible fallback (old versions): assume constant UV
            accumulatedUVIndexSeconds = max(0, currentUVIndex) * max(0, Date().timeIntervalSince(start))
        }
        
        if defaults.object(forKey: StorageKey.burnLimitUVIndexSeconds) != nil {
            burnLimitUVIndexSeconds = defaults.double(forKey: StorageKey.burnLimitUVIndexSeconds)
        } else {
            // Backward-compatible fallback: assume the original planned duration at constant UV
            let totalSeconds = max(1, Int(end.timeIntervalSince(start)))
            burnLimitUVIndexSeconds = defaultBurnLimitUVIndexSeconds(seconds: totalSeconds, uvIndex: currentUVIndex)
        }
        
        lastDoseUpdateDate = defaults.object(forKey: StorageKey.lastDoseUpdateDate) as? Date ?? Date()
        uvDose = accumulatedUVIndexSeconds / 4000.0

        let now = Date()
        let remaining = Int(end.timeIntervalSince(now).rounded(.down))
        if remaining > 0 {
            isTimerRunning = true
            secondsLeft = remaining
            secondsElapsed = max(0, Int(now.timeIntervalSince(start)))
            
            // Update dose immediately (incl. time spent while app was inactive)
            accumulateDose(until: min(now, end))

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
            secondsElapsed = 0
            uvDose = 0

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
    
    private func defaultBurnLimitUVIndexSeconds(seconds: Int, uvIndex: Double) -> Double {
        // burnLimitUVIndexSeconds is ∫UV dt at the burn threshold (UVIndex * seconds).
        // If UV is 0 (night), fall back to treating "seconds" as a UV=1 reference.
        if uvIndex > 0 {
            return uvIndex * Double(max(1, seconds))
        }
        return Double(max(1, seconds))
    }
    
    private func calculateRemainingSeconds(forUVIndex uvIndex: Double) -> Int {
        let remainingUVIndexSeconds = max(0, burnLimitUVIndexSeconds - accumulatedUVIndexSeconds)
        guard uvIndex > 0 else { return 43200 } // Max 12 hours when UV == 0
        let calculatedSeconds = Int((remainingUVIndexSeconds / uvIndex).rounded(.up))
        // Cap at 12 hours (43,200 seconds)
        return min(calculatedSeconds, 43200)
    }
    
    private func accumulateDose(until date: Date) {
        guard isTimerRunning else { return }
        let last = lastDoseUpdateDate ?? date
        let delta = date.timeIntervalSince(last)
        guard delta > 0 else {
            lastDoseUpdateDate = date
            return
        }
        
        // Integrate in UVIndexSeconds (∫UV dt), convert to SED for display:
        // SED ≈ (∫UV dt) / 4000
        accumulatedUVIndexSeconds += max(0, currentUVIndex) * delta
        uvDose = accumulatedUVIndexSeconds / 4000.0
        lastDoseUpdateDate = date
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

