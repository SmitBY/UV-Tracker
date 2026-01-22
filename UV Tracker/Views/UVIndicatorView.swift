//
//  UVIndicatorView.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import SwiftUI

struct UVIndicatorView: View {
    let uvIndex: Double

    var body: some View {
        ZStack {
            // Outer Circle Gradient (390x390)
            Circle()
                .fill(
                    AngularGradient(
                        stops: [
                            .init(color: Color(hex: "6FFF00"), location: 0),      // Green
                            .init(color: Color(hex: "FDE800"), location: 0.14),   // Yellow
                            .init(color: Color(hex: "FD8102"), location: 0.34),   // Orange
                            .init(color: Color(hex: "FD0004"), location: 0.51),   // Red
                            .init(color: Color(hex: "9900FF"), location: 0.81),   // Purple
                            .init(color: Color(hex: "6FFF00"), location: 1.0)     // Back to Green
                        ],
                        center: .center,
                        angle: .degrees(90) // Start from bottom
                    )
                )
                .frame(width: 390, height: 390)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 6)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 5)

            // Triangle Pointer (62x62 white triangle)
            Triangle()
                .fill(Color.white)
                .frame(width: 62, height: 62)
                .offset(y: -128) // Distance from center
                .rotationEffect(.degrees(180 + (min(uvIndex, 11.0) / 11.0) * 180.0)) // Rotate based on UV index
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)

            // Central Circle (240x240 with gradient)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FDFDFD"), Color(hex: "E5E3E3")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 240, height: 240)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)

            // UV Index Number and Label
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.0f", uvIndex))
                    .font(.system(size: 96, weight: .medium, design: .default))
                    .foregroundColor(.black)
                    .kerning(-1)

                Text(String(localized: "uv_index_label"))
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .foregroundColor(.black)
                    .kerning(-1)
                    .offset(y: 8)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Triangle pointing downward (outward from center)
        path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // Bottom center
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // Top left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // Top right
        path.closeSubpath()
        return path
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

#Preview {
    UVIndicatorView(uvIndex: 5.4)
}

