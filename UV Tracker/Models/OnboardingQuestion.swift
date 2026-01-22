//
//  OnboardingQuestion.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import Foundation

struct OnboardingAnswer: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let score: Int
}

struct OnboardingQuestion: Identifiable {
    let id: Int
    let title: String
    let answers: [OnboardingAnswer]
}

enum OnboardingStep: Hashable {
    case welcome
    case locationRequest
    case question(Int)
    case subscription
    case result
}


