//
//  PurchaseManager.swift
//  weather
//

import StoreKit

@Observable
@MainActor
class PurchaseManager {
    static let productID = "com.mootielabs.weather.removeads"

    private(set) var product: Product?
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    var errorMessage: String?
    private var updatesTask: Task<Void, Never>?

    var adsRemoved: Bool = UserDefaults.standard.bool(forKey: "adsRemoved") {
        didSet { UserDefaults.standard.set(adsRemoved, forKey: "adsRemoved") }
    }

    init() {
        Task { await loadProduct() }
        Task { await checkExistingPurchases() }
        updatesTask = Task { await listenForTransactionUpdates() }
    }


    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            print("[StoreKit] Products fetched: \(products.map(\.id))")
            product = products.first
        } catch {
            print("[StoreKit] loadProduct error: \(error)")
        }
    }

    func purchase() async {
        if product == nil {
            await loadProduct()
        }
        guard let product else {
            print("[StoreKit] Product still nil after retry.")
            errorMessage = "Unable to load purchase. Please check your connection and try again."
            return
        }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    adsRemoved = true
                    await transaction.finish()
                case .unverified:
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
    }

    func restore() async {
        isRestoring = true
        errorMessage = nil
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await checkExistingPurchases()
            if !adsRemoved {
                errorMessage = "No purchases found on this Apple ID."
            }
        } catch {
            errorMessage = "Restore failed. Please try again."
        }
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                adsRemoved = true
                await transaction.finish()
            }
        }
    }

    private func checkExistingPurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID {
                adsRemoved = true
                return
            }
        }
    }
}
