//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import ComposableArchitecture
import SwiftUI

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

/// お気に入りの素数一覧のView
public struct FavoritesView : View {

    @ObservedObject var store: Store<FavoritePrimesState, FavoriteAction>

    public init(store: Store<FavoritePrimesState, FavoriteAction>) {
        self.store = store
    }

    public var body: some View {
        List {
            ForEach(store.value.favoritePrimes, id: \.self) { prime in
                Text("\(prime)")
                    .swipeActions {
                        Button("Delete") {
                            store.send(.removeFromFavorite(prime))
                        }
                        .tint(.red)
                    }
            }
        }
    }
}
