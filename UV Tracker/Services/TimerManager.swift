//
//  TimerManager.swift
//  UV Tracker
//
//  Created by Dmitriy on 26/12/2025.
//

import Foundation
import Combine
import ActivityKit

@MainActor
class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    @Published var secondsLeft: Int = 0
    @Published var isTimerRunning: Bool = false
    @Published var currentUVIndex: Double = 0
    
    private var timer: AnyCancellable?
    private var activity: Activity<UVActivityAttributes>?
    
    private init() {}
    
    func startTimer(seconds: Int, uvIndex: Double) {
        self.secondsLeft = seconds
        self.currentUVIndex = uvIndex
        self.isTimerRunning = true
        
        // Start Live Activity
        startLiveActivity(seconds: seconds, uvIndex: uvIndex)
        
        // Schedule Notification
        NotificationManager.shared.scheduleTimerFinishedNotification(seconds: seconds)
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.tick()
                }
            }
    }
    
    func stopTimer() {
        isTimerRunning = false
        timer?.cancel()
        timer = nil
        
        NotificationManager.shared.cancelAllNotifications()
        
        Task {
            await stopLiveActivity()
        }
    }
    
    func addTenMinutes() {
        secondsLeft += 600
        updateLiveActivity()
        NotificationManager.shared.scheduleTimerFinishedNotification(seconds: secondsLeft)
    }
    
    private func tick() {
        if secondsLeft > 0 {
            secondsLeft -= 1
            if secondsLeft % 10 == 0 { // Update Live Activity every 10 seconds to save battery
                updateLiveActivity()
            }
        } else {
            stopTimer()
            // Notification will be triggered by background system
        }
    }
    
    // MARK: - Live Activity
    
    private func startLiveActivity(seconds: Int, uvIndex: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = UVActivityAttributes()
        let initialState = UVActivityAttributes.ContentState(
            secondsLeft: seconds,
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
        Task {
            let updatedState = UVActivityAttributes.ContentState(
                secondsLeft: secondsLeft,
                uvIndex: currentUVIndex
            )
            let content = ActivityContent(state: updatedState, staleDate: nil)
            await activity?.update(content)
        }
    }
    
    private func stopLiveActivity() async {
        let finalState = UVActivityAttributes.ContentState(
            secondsLeft: 0,
            uvIndex: currentUVIndex
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        await activity?.end(content, dismissalPolicy: .immediate)
        activity = nil
    }
}

