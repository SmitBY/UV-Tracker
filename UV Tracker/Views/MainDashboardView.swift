//
//  MainDashboardView.swift
//  UV Tracker
//
//  Created by Dmitriy on 26/12/2025.
//

import SwiftUI

struct MainDashboardView: View {
    @StateObject private var viewModel = UVViewModel()
    @StateObject private var storeManager = StoreManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                // Header: Time to get sunburn (left aligned with 16px padding)
                VStack(alignment: .leading, spacing: -15) {
                    Text("dashboard_time_to_burn")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.primary)
                        .kerning(-1)

                    Text(formatSeconds(viewModel.timerManager.isTimerRunning ? viewModel.timerManager.secondsLeft : viewModel.timeToBurnSeconds))
                        .font(.system(size: 80, weight: .medium, design: .default))
                        .foregroundColor(.primary)
                        .kerning(-1)
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .padding(.leading, 16)
                .position(x: geometry.size.width/2, y: 84) // Match CSS top: 84px

                // UV Indicator Circle (positioned at 178px left, 161px top)
                UVIndicatorView(uvIndex: viewModel.currentUV)
                    .position(x: 178 + 195, y: 161 + 165) // Center of circle - match CSS top: 161px

                // Recommended section (label + card together)
                VStack(alignment: .leading, spacing: 4) {
                    // Label above the card
                    Text("dashboard_recommended")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundColor(.secondary)

                    // Card below the label
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SPF \(viewModel.selectedSPF)")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.primary)
                            .kerning(-1)
                        Text("protection_cream")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 90, height: 120, alignment: .topLeading)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(6)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                }
                .position(x: 16 + 45, y: 225) // Center of the combined element

                // Max UV Card (positioned below Recommended, same vertical line)
                VStack(spacing: 15) {
                    Text("dashboard_max_uv")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.primary)

                    ZStack {
                        Circle()
                            .stroke(Color(hex: "AF05FE"), lineWidth: 4)
                            .frame(width: 50, height: 50)

                        Text("\(Int(viewModel.maxUVToday))")
                            .font(.system(size: 24.5, weight: .medium, design: .default))
                            .foregroundColor(.primary)
                            .kerning(-1)
                    }
                }
                .frame(width: 90, height: 120)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(6)
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                .position(x: 16 + 45, y: 415 + 7) // Match CSS top: 415px

                // Session Info Bar (positioned at 16px left, 632px top)
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(width: 369, height: 100)
                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)

                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("dashboard_time_spent")
                                .font(.system(size: 12, weight: .regular, design: .default))
                                .foregroundColor(.secondary)
                            Text("\(44)m") // Mock data
                                .font(.system(size: 32, weight: .medium, design: .default))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 120, alignment: .leading)

                        Spacer()

                        VStack(alignment: .leading, spacing: 0) {
                            Text("dashboard_uv_dose")
                                .font(.system(size: 12, weight: .regular, design: .default))
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", viewModel.uvDose))")
                                .font(.system(size: 32, weight: .medium, design: .default))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 80, alignment: .leading)

                        Spacer()

                        // +10m Button
                        Button(action: {
                            viewModel.timerManager.addTenMinutes()
                        }) {
                            VStack(spacing: 0) {
                                Text("action_add_10")
                                    .font(.system(size: 15, weight: .semibold, design: .default))
                                    .foregroundColor(.white)
                                Text("min")
                                    .font(.system(size: 10, weight: .regular, design: .default))
                                    .foregroundColor(Color(hex: "3A4482"))
                                    .offset(y: -3)
                            }
                        }
                        .frame(width: 80, height: 80)
                        .background(Color(hex: "818CD5"))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(width: 369, height: 100)
                .position(x: 16 + 184.5, y: 600) // Center of bar

                // Start/Stop Button (positioned below session info bar)
                Button(action: {
                    withAnimation {
                        if viewModel.timerManager.isTimerRunning {
                            viewModel.timerManager.stopTimer()
                        } else {
                            viewModel.startSession()
                        }
                    }
                }) {
                    Text(viewModel.timerManager.isTimerRunning ? "button_stop" : "button_start")
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(viewModel.timerManager.isTimerRunning ? .white : Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.timerManager.isTimerRunning ? Color.red : Color.primary)
                        .cornerRadius(12)
                }
                .frame(width: geometry.size.width - 32, height: 50)
                .position(x: geometry.size.width/2, y: 675) // Below session info bar
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}


#Preview {
    MainDashboardView()
}
