//
//  StoreManager.swift
//  hold-it-ios
//

import Foundation
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

/// 恢复购买状态
enum RestoreState {
    case idle                // 默认
    case restoring           // 正在恢复
    case success             // 恢复成功
    case noPurchases         // 未找到购买记录
    case notSignedIn         // 未登录 Apple ID
    case networkError        // 网络错误
    case failed(String)      // 其他错误
}

@MainActor
@Observable
class StoreManager {
    /// 会员状态（启动时先用本地缓存乐观显示，再以 StoreKit 校验结果为准）
    var isVip: Bool {
        didSet {
            UserDefaults.standard.set(isVip, forKey: Self.isVipCacheKey)
        }
    }
    var product: Product?
    var isLoading: Bool = true
    var purchaseState: PurchaseState = .idle
    var restoreState: RestoreState = .idle

    /// 产品本地化价格字符串
    var displayPrice: String {
        product?.displayPrice ?? ""
    }

    private let productID = "mj.holdit.lifetimeVip"
    private static let isVipCacheKey = "mj.holdit.isVipCached"
    private var transactionListener: Task<Void, Never>?

    private var entitlementChecked = false

    init() {
        // 先用本地缓存恢复会员状态，避免冷启动校验前 UI 误判为非会员
        self.isVip = UserDefaults.standard.bool(forKey: Self.isVipCacheKey)
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
                            // 退款/撤销时同步降级
                            if transaction.revocationDate != nil {
                                isVip = false
                            } else {
                                isVip = true
                            }
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
        // 不立刻把 isVip 置 false：避免 StoreKit 异步查询期间或查询失败时 UI 闪烁回非会员
        var found = false
        var revoked = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productID {
                if transaction.revocationDate != nil {
                    // 明确退款/撤销 → 降级
                    revoked = true
                } else {
                    found = true
                }
                break
            }
        }

        if found {
            // 找到有效权益
            isVip = true
        } else if revoked {
            // 明确被退款/撤销
            isVip = false
        }
        // 未找到交易且未撤销 → 保持当前值（缓存）
        // 沙盒环境下 Transaction.currentEntitlements 冷启动经常返回空结果，
        // 不能因为查不到就否定已有的购买状态

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
        restoreState = .restoring

        do {
            try await AppStore.sync()
            await checkEntitlements()

            if isVip {
                restoreState = .success
            } else {
                restoreState = .noPurchases
            }
        } catch let error as StoreKitError {
            switch error {
            case .networkError:
                restoreState = .networkError
            default:
                restoreState = .failed(error.localizedDescription)
            }
        } catch is URLError {
            restoreState = .networkError
        } catch {
            // 用户未登录 Apple ID 时 AppStore.sync() 会抛错
            if (error as NSError).code == 3083 {
                restoreState = .notSignedIn
            } else {
                restoreState = .failed(error.localizedDescription)
            }
        }
    }

    /// 重置恢复状态
    func resetRestoreState() {
        restoreState = .idle
    }
}