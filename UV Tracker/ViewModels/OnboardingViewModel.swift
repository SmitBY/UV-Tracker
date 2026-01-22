//
//  OnboardingViewModel.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var totalScore: Int = 0
    @Published var selectedAnswerID: UUID?
    
    let questions: [OnboardingQuestion] = [
        OnboardingQuestion(id: 1, titleKey: "q1_title", answers: [
            OnboardingAnswer(textKey: "q1_a0", score: 0),
            OnboardingAnswer(textKey: "q1_a1", score: 1),
            OnboardingAnswer(textKey: "q1_a2", score: 2),
            OnboardingAnswer(textKey: "q1_a3", score: 3),
            OnboardingAnswer(textKey: "q1_a4", score: 4)
        ]),
        OnboardingQuestion(id: 2, titleKey: "q2_title", answers: [
            OnboardingAnswer(textKey: "q2_a0", score: 0),
            OnboardingAnswer(textKey: "q2_a1", score: 1),
            OnboardingAnswer(textKey: "q2_a2", score: 2),
            OnboardingAnswer(textKey: "q2_a3", score: 3),
            OnboardingAnswer(textKey: "q2_a4", score: 4)
        ]),
        OnboardingQuestion(id: 3, titleKey: "q3_title", answers: [
            OnboardingAnswer(textKey: "q3_a0", score: 0),
            OnboardingAnswer(textKey: "q3_a1", score: 1),
            OnboardingAnswer(textKey: "q3_a2", score: 2),
            OnboardingAnswer(textKey: "q3_a3", score: 3),
            OnboardingAnswer(textKey: "q3_a4", score: 4)
        ]),
        OnboardingQuestion(id: 4, titleKey: "q4_title", answers: [
            OnboardingAnswer(textKey: "q4_a0", score: 0),
            OnboardingAnswer(textKey: "q4_a1", score: 1),
            OnboardingAnswer(textKey: "q4_a2", score: 2),
            OnboardingAnswer(textKey: "q4_a3", score: 3),
            OnboardingAnswer(textKey: "q4_a4", score: 4)
        ]),
        OnboardingQuestion(id: 5, titleKey: "q5_title", answers: [
            OnboardingAnswer(textKey: "q5_a0", score: 0),
            OnboardingAnswer(textKey: "q5_a1", score: 1),
            OnboardingAnswer(textKey: "q5_a2", score: 2),
            OnboardingAnswer(textKey: "q5_a3", score: 3),
            OnboardingAnswer(textKey: "q5_a4", score: 4)
        ]),
        OnboardingQuestion(id: 6, titleKey: "q6_title", answers: [
            OnboardingAnswer(textKey: "q6_a0", score: 0),
            OnboardingAnswer(textKey: "q6_a1", score: 1),
            OnboardingAnswer(textKey: "q6_a2", score: 2),
            OnboardingAnswer(textKey: "q6_a3", score: 3),
            OnboardingAnswer(textKey: "q6_a4", score: 4)
        ]),
        OnboardingQuestion(id: 7, titleKey: "q7_title", answers: [
            OnboardingAnswer(textKey: "q7_a1", score: 1),
            OnboardingAnswer(textKey: "q7_a2", score: 2),
            OnboardingAnswer(textKey: "q7_a3", score: 3),
            OnboardingAnswer(textKey: "q7_a4", score: 4),
            OnboardingAnswer(textKey: "q7_a5", score: 5)
        ]),
        OnboardingQuestion(id: 8, titleKey: "q8_title", answers: [
            OnboardingAnswer(textKey: "q8_a0", score: 0),
            OnboardingAnswer(textKey: "q8_a1", score: 1),
            OnboardingAnswer(textKey: "q8_a2", score: 2),
            OnboardingAnswer(textKey: "q8_a3", score: 3),
            OnboardingAnswer(textKey: "q8_a4", score: 4)
        ]),
        OnboardingQuestion(id: 9, titleKey: "q9_title", answers: [
            OnboardingAnswer(textKey: "q9_a0", score: 0),
            OnboardingAnswer(textKey: "q9_a1", score: 1),
            OnboardingAnswer(textKey: "q9_a2", score: 2),
            OnboardingAnswer(textKey: "q9_a3", score: 3),
            OnboardingAnswer(textKey: "q9_a4", score: 4)
        ]),
        OnboardingQuestion(id: 10, titleKey: "q10_title", answers: [
            OnboardingAnswer(textKey: "q10_a0", score: 0),
            OnboardingAnswer(textKey: "q10_a1", score: 1),
            OnboardingAnswer(textKey: "q10_a2", score: 2),
            OnboardingAnswer(textKey: "q10_a3", score: 3),
            OnboardingAnswer(textKey: "q10_a4", score: 4)
        ])
    ]
    
    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .locationRequest
        case .locationRequest:
            currentStep = .question(1)
        case .question(let id):
            if let answerID = selectedAnswerID,
               let question = questions.first(where: { $0.id == id }),
               let answer = question.answers.first(where: { $0.id == answerID }) {
                totalScore += answer.score
            }
            
            if id < 10 {
                currentStep = .question(id + 1)
                selectedAnswerID = nil
            } else {
                currentStep = .subscription
            }
        case .subscription:
            currentStep = .result
        case .result:
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        let skinType = calculateSkinType()
        ProfileManager.shared.updateSkinType(skinType)
        ProfileManager.shared.completeOnboarding()
    }
    
    private func calculateSkinType() -> SkinType {
        switch totalScore {
        case 0...6: return .type1
        case 7...12: return .type2
        case 13...18: return .type3
        case 19...24: return .type4
        case 25...30: return .type5
        default: return .type6
        }
    }
}

