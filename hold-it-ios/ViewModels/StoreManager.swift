//
//  StoreManager.swift
//  hold-it-ios
//

import SwiftUI
import StoreKit

/// 购买状态枚举
enum PurchaseState {
    case idle         // 默认状态
    case purchasing   // 正在购买
    case success      // 购买成功
    case failed       // 购买失败
    case cancelled    // 用户取消
}

@MainActor
@Observable
class StoreManager {
    var isVip: Bool = false
    var product: Product?
    var isLoading: Bool = true
    var purchaseState: PurchaseState = .idle

    /// 产品本地化价格字符串
    var displayPrice: String {
        product?.displayPrice ?? ""
    }

    private let productID = "mj.holdit.lifetimeVip"
    private var transactionListener: Task<Void, Never>?

    private var entitlementChecked = false

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await checkEntitlements()
            isLoading = false
        }
    }

    // MARK: - 持续监听交易更新（主线程更新 UI 状态）
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await MainActor.run {
                        if transaction.productID == productID {
                            isVip = true
                        }
                    }
                    await transaction.finish()
                }
            }
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
        // 先重置为 false， 再逐条检查
        isVip = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productID {
                isVip = true
                break  // 找到有效权益即停止
            }
        }
        entitlementChecked = true
    }

    func purchase() async -> Bool {
        guard let product = product else {
            purchaseState = .failed
            return false
        }

        purchaseState = .purchasing

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    isVip = true
                    purchaseState = .success
                    await transaction.finish()
                    return true
                } else {
                    purchaseState = .failed
                }
            case .userCancelled:
                purchaseState = .cancelled
            case .pending:
                // 交易待审核（如家长审批）
                purchaseState = .idle
            @unknown default:
                purchaseState = .failed
            }
        } catch {
            print("Purchase failed: \(error)")
            purchaseState = .failed
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