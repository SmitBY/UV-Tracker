//
//  StoreManager.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var isPremium: Bool = false
    @Published var products: [Product] = []
    
    private var updates: Task<Void, Never>? = nil
    private let premiumProductID = "com.uvtracker.premium"
    
    private init() {
        self.updates = observeTransactionUpdates()
        Task {
            await fetchProducts()
            await updatePremiumStatus()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    func fetchProducts() async {
        do {
            self.products = try await Product.products(for: [premiumProductID])
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    func purchase() async throws {
        guard let product = products.first else { return }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                ProfileManager.shared.setPremium(true)
                self.isPremium = true
                await transaction.finish()
            case .unverified:
                break
            }
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePremiumStatus()
    }
    
    private func updatePremiumStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumProductID {
                    ProfileManager.shared.setPremium(true)
                    self.isPremium = true
                    return
                }
            }
        }
        self.isPremium = false
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await _ in Transaction.updates {
                await updatePremiumStatus()
            }
        }
    }
}
