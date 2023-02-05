//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import Foundation

/// お気に入り一覧で使うstate
public struct FavoritePrimesState {
    public var favoritePrimes: [Int]

    public init(favoritePrimes: [Int]) {
        self.favoritePrimes = favoritePrimes
    }
}

/// お気に入り一覧でのアクション
public enum FavoriteAction {
    case removeFromFavorite(Int)
}

/// FavoriteViewで使うreducer
public func favoriteReducer(value: inout FavoritePrimesState, action: FavoriteAction) -> Void {
    switch action {
    case .removeFromFavorite(let number):
        value.favoritePrimes.removeAll(where: { $0 == number })
    }
}
