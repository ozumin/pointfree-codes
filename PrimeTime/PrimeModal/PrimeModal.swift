//
//  PrimeModal.swift
//  PrimeModal
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import ComposableArchitecture
import SwiftUI

public typealias PrimeModalState = (targetNumber: Int, favoritePrimes: [Int])

/// 素数結果表示時のアクション
public enum PrimeResultAction: Equatable {
    case addToFavorite
    case removeFromFavorite
}

/// PrimeResultViewでのreducer
public func primeResultReducer(value: inout PrimeModalState, action: PrimeResultAction, environment: Void) -> [Effect<PrimeResultAction>] {
    switch action {
    case .addToFavorite:
        value.favoritePrimes.append(value.targetNumber)
        return []
    case .removeFromFavorite:
        value.favoritePrimes.removeAll(where: { $0 == value.targetNumber })
        return []
    }
}

/// CounterViewでsheet表示する素数の結果のView
public struct PrimeResultView: View {

    @ObservedObject var store: Store<PrimeModalState, PrimeResultAction>

    public init(store: Store<PrimeModalState, PrimeResultAction>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            if isPrime(store.value.targetNumber) {
                Text("\(store.value.targetNumber) is prime 🎉")
                if store.value.favoritePrimes.contains(store.value.targetNumber) {
                    Button {
                        store.send(.removeFromFavorite)
                    } label: {
                        Text("Remove from favorite primes")
                    }
                } else {
                    Button {
                        store.send(.addToFavorite)
                    } label: {
                        Text("Save to favorite primes")
                    }
                }
            } else {
                Text("\(store.value.targetNumber) is not prime 😢")
            }
        }
    }
}

/// 素数計算用の関数
func isPrime(_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}
