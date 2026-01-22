//
//  OnboardingView.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient from UI2
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "FBDF95"), location: 0),
                    .init(color: Color(hex: "F5D2C0"), location: 0.2189),
                    .init(color: Color(hex: "F6F7F9"), location: 0.6368),
                    .init(color: Color(hex: "F6F7F9"), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                switch viewModel.currentStep {
                case .welcome:
                    welcomeScreen
                case .locationRequest:
                    locationRequestScreen
                case .question(let id):
                    if let question = viewModel.questions.first(where: { $0.id == id }) {
                        questionScreen(question)
                    }
                case .subscription:
                    subscriptionScreen
                case .result:
                    resultScreen
                }
                
                if case .question(let id) = viewModel.currentStep {
                    pageControl(current: id, total: 10)
                        .padding(.bottom, 20)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 34)
        }
    }
    
    // MARK: - Screens
    
    private var welcomeScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer().frame(height: 100)
            
            Text("welcome_title")
                .font(.system(size: 32, weight: .bold))
                .kerning(-1)
                .foregroundColor(.black)
            
            Text("welcome_subtitle")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "636363"))
                .lineSpacing(4)
            
            Spacer()
            
            continueButton
        }
        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
    }
    
    private var locationRequestScreen: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer().frame(height: 100)
            
            Text("location_title")
                .font(.system(size: 32, weight: .bold))
                .kerning(-1)
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 16) {
                LocationBenefitRow(textKey: "location_benefit_1")
                LocationBenefitRow(textKey: "location_benefit_2")
                LocationBenefitRow(textKey: "location_benefit_3")
                LocationBenefitRow(textKey: "location_benefit_4")
            }
            .padding(.top, 20)
            
            Spacer()
            
            continueButton
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }
    
    private func questionScreen(_ question: OnboardingQuestion) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer().frame(height: 100)
            
            Text(LocalizedStringKey(question.titleKey))
                .font(.system(size: 32, weight: .bold))
                .kerning(-1)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(question.answers) { answer in
                        LiquidGlassButton(
                            textKey: LocalizedStringKey(answer.textKey),
                            isSelected: viewModel.selectedAnswerID == answer.id
                        ) {
                            withAnimation(.spring()) {
                                viewModel.selectedAnswerID = answer.id
                            }
                        }
                    }
                }
                .padding(.vertical, 10)
            }
            .padding(.top, 20)
            
            Spacer()
            
            continueButton
                .disabled(viewModel.selectedAnswerID == nil)
                .opacity(viewModel.selectedAnswerID == nil ? 0.5 : 1.0)
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }
    
    private var subscriptionScreen: some View {
        SubscriptionPaywallView(mode: .onboarding(continueAction: {
            withAnimation {
                viewModel.nextStep()
            }
        }))
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }
    
    private var resultScreen: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("result_ready")
                .font(.system(size: 32, weight: .bold))
                .kerning(-1)
                .foregroundColor(.black)
            Spacer()
            continueButton
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
    }
    
    // MARK: - Components
    
    private func pageControl(current: Int, total: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.black : Color.black.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var continueButton: some View {
        Button(action: {
            withAnimation {
                viewModel.nextStep()
            }
        }) {
            Text("onboarding_continue")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FFBB00"), Color(hex: "FFEBB3")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(36.5)
        }
        .padding(.bottom, 50)
    }
}

struct LocationBenefitRow: View {
    let textKey: LocalizedStringKey
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "818CD5"))
            Text(textKey)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "636363"))
        }
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case week
    case year
    case welcomeOffer
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .week: return "One week"
        case .year: return "One Year"
        case .welcomeOffer: return "Welcome offer"
        }
    }
    
    var price: String {
        switch self {
        case .week: return "$4.99"
        case .year: return "$89.99/Year"
        case .welcomeOffer: return "$24.99/Year"
        }
    }
    
    var subPrice: String {
        switch self {
        case .week: return "$5/Month"
        case .year: return "$2.92/Month"
        case .welcomeOffer: return "$2.92/Month"
        }
    }
    
    var badge: String? {
        switch self {
        case .year: return "MOST POPULAR"
        default: return nil
        }
    }
    
    var discount: String? {
        switch self {
        case .year: return "-42%"
        default: return nil
        }
    }
    
    var subtitle: String? {
        switch self {
        case .welcomeOffer: return "One year"
        default: return nil
        }
    }
}

struct SubscriptionPaywallView: View {
    enum Mode {
        case onboarding(continueAction: () -> Void)
        case profile
    }
    
    @ObservedObject private var storeManager = StoreManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let mode: Mode
    
    @State private var selectedPlan: SubscriptionPlan = .year
    @State private var isPurchasing: Bool = false
    @State private var isRestoring: Bool = false
    @State private var errorMessage: String?
    
    private var showsCloseButton: Bool {
        if case .profile = mode { return true }
        return false
    }
    
    private var primaryButtonTitleKey: LocalizedStringKey {
        switch mode {
        case .onboarding:
            return "onboarding_continue"
        case .profile:
            return "subscription_title"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            topBar
            
            Spacer().frame(height: 50)
            
            Text("subscription_title")
                .font(.system(size: 32, weight: .bold))
                .kerning(-1)
                .foregroundColor(.black)
            
            Text("subscription_description")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "636363"))
            
            VStack(spacing: 10) {
                ForEach(SubscriptionPlan.allCases) { plan in
                    Button {
                        withAnimation(.spring()) {
                            selectedPlan = plan
                        }
                    } label: {
                        SubscriptionCard(
                            title: plan.title,
                            price: plan.price,
                            subPrice: plan.subPrice,
                            isSelected: selectedPlan == plan,
                            badge: plan.badge,
                            discount: plan.discount,
                            subtitle: plan.subtitle
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
            Button {
                switch mode {
                case .onboarding(let continueAction):
                    continueAction()
                case .profile:
                    Task { @MainActor in
                        guard !isPurchasing else { return }
                        isPurchasing = true
                        defer { isPurchasing = false }
                        
                        do {
                            try await storeManager.purchase()
                            if storeManager.isPremium {
                                dismiss()
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.black)
                    }
                    Text(primaryButtonTitleKey)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "00D0FF"), Color(hex: "B3F7FF")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(36.5)
                .opacity(isPurchasing ? 0.8 : 1.0)
            }
            .disabled(isPurchasing)
            .padding(.bottom, 50)
        }
        .alert("Error", isPresented: Binding(get: {
            errorMessage != nil
        }, set: { isPresented in
            if !isPresented { errorMessage = nil }
        })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private var topBar: some View {
        HStack {
            if showsCloseButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Button {
                Task { @MainActor in
                    guard !isRestoring else { return }
                    isRestoring = true
                    defer { isRestoring = false }
                    
                    do {
                        try await storeManager.restorePurchases()
                        if storeManager.isPremium, showsCloseButton {
                            dismiss()
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Group {
                    if isRestoring {
                        ProgressView()
                            .tint(Color(hex: "636363"))
                    } else {
                        Text("already_purchased")
                            .underline()
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "636363"))
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 20)
    }
}

struct LiquidGlassButton: View {
    let textKey: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(textKey)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52) // Slightly taller for better touch target
                .background(
                    ZStack {
                        // Background fill
                        if isSelected {
                            Color.white.opacity(0.6)
                        } else {
                            Color.white.opacity(0.25) // Increased opacity from 0.1 to 0.25
                        }
                        
                        // Glass stroke
                        RoundedRectangle(cornerRadius: 1000)
                            .stroke(isSelected ? Color.black.opacity(0.2) : Color.white.opacity(0.5), lineWidth: 1.5)
                    }
                )
                .clipShape(Capsule())
                // Stronger shadow for better separation from the gradient background
                .shadow(color: .black.opacity(isSelected ? 0.15 : 0.08), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct SubscriptionCard: View {
    let title: String
    let price: String
    let subPrice: String
    let isSelected: Bool
    var badge: String? = nil
    var discount: String? = nil
    var subtitle: String? = nil
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .medium))
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(price)
                        .font(.system(size: 20, weight: .medium))
                    Text(subPrice)
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(hex: "00FF1E").opacity(0.3) : Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            )
            .background(Blur(style: .systemUltraThinMaterialLight))
            .cornerRadius(16)
            
            if let badge = badge {
                HStack(spacing: 4) {
                    Text(badge)
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: "FFBB00"))
                        .cornerRadius(3)
                    
                    if let discount = discount {
                        Text(discount)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: "FFBB00"))
                            .cornerRadius(3)
                    }
                }
                .offset(x: 20, y: -10)
            }
        }
    }
}

struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.isUserInteractionEnabled = false
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView()
}
