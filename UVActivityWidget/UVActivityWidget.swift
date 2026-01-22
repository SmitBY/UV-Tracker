//
//  UVActivityWidget.swift
//  UV Tracker
//
//  Created by Dmitriy on 26/12/2025.
//

import WidgetKit
import SwiftUI
import ActivityKit

struct UVActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: UVActivityAttributes.self) { context in
            // Lock Screen UI
            VStack {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text("UV Tracker")
                        .font(.headline)
                    Spacer()
                    Text("UV: \(String(format: "%.1f", context.state.uvIndex))")
                        .bold()
                }
                
                HStack {
                    Text("widget_remains")
                    Spacer()
                    Text(context.state.endDate, style: .timer)
                        .font(.title2)
                        .monospacedDigit()
                        .bold()
                }
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.orange)
                        Text("\(String(format: "%.1f", context.state.uvIndex))")
                            .bold()
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.endDate, style: .timer)
                        .monospacedDigit()
                        .bold()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("UV Tracker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Stay safe in the sun!")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
            } compactLeading: {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(context.state.endDate, style: .timer)
                    .monospacedDigit()
                    .bold()
            } minimal: {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
            }
        }
    }
}

@main
struct UVActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        UVActivityWidget()
    }
}
