//
//  StoreManager.swift
//  hold-it-ios
//

import SwiftUI
import StoreKit

@Observable
class StoreManager {
    var isVip: Bool = false // TODO: 模拟付费成功，真实对接时改回 false
    var product: Product?
    
    private let productID = "lifetime_vip"
    
    init() {
        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID {
                isVip = true
            }
        }
    }
    
    func purchase() async -> Bool {
        guard let product = product else { return false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    isVip = true
                    await transaction.finish()
                    return true
                }
            case .userCancelled:
                break
            default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
        return false
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            print("Restore failed: \(error)")
        }
    }
}
