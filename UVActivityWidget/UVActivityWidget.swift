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
                    Text(formatSeconds(context.state.secondsLeft))
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
                    Text(formatSeconds(context.state.secondsLeft))
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
                Text(formatSeconds(context.state.secondsLeft))
                    .monospacedDigit()
                    .bold()
            } minimal: {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

@main
struct UVActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        UVActivityWidget()
    }
}

struct UVActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        UVActivityWidget()
            .previewContext(ActivityPreviewContext(
                activity: Activity(
                    attributes: UVActivityAttributes(),
                    content: ActivityContent(
                        state: UVActivityAttributes.ContentState(secondsLeft: 1800, uvIndex: 8.5),
                        staleDate: nil
                    )
                )
            ))
    }
}
