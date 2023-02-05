//
//  PrimeModal.swift
//  PrimeModal
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import Foundation

public struct PrimeModalState {
    public var favoritePrimes: [Int]
    public let targetNumber: Int

    public init(favoritePrimes: [Int], targetNumber: Int) {
        self.favoritePrimes = favoritePrimes
        self.targetNumber = targetNumber
    }
}

/// 素数結果表示時のアクション
public enum PrimeResultAction {
    case addToFavorite
    case removeFromFavorite
}

/// PrimeResultViewでのreducer
public func primeResultReducer(value: inout PrimeModalState, action: PrimeResultAction) -> Void {
    switch action {
    case .addToFavorite:
        value.favoritePrimes.append(value.targetNumber)
    case .removeFromFavorite:
        value.favoritePrimes.removeAll(where: { $0 == value.targetNumber })
    }
}
