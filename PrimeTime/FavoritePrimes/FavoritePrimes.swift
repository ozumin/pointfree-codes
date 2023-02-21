//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import ComposableArchitecture
import SwiftUI

/// お気に入り一覧でのアクション
public enum FavoriteAction {
    case removeFromFavorite(Int)
    case loadedFavoritePrimes([Int])
    case saveButtonTapped
}

/// FavoriteViewで使うreducer
public func favoriteReducer(value: inout [Int], action: FavoriteAction) -> Effect {
    switch action {
    case .removeFromFavorite(let number):
        value.removeAll(where: { $0 == number })
        return {}
    case .loadedFavoritePrimes(let favoritePrimes):
        value = favoritePrimes
        return {}
    case .saveButtonTapped:
        let newValue = value
        return {
            let data = try! JSONEncoder().encode(newValue)
            let documentsPath = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            )[0]
            let documentsUrl = URL(fileURLWithPath: documentsPath)
            let favoritePrimesUrl = documentsUrl
                .appendingPathComponent("favorite-primes.json")
            try! data.write(to: favoritePrimesUrl)
        }
    }
}

/// お気に入りの素数一覧のView
public struct FavoritesView : View {

    @ObservedObject var store: Store<[Int], FavoriteAction>

    public init(store: Store<[Int], FavoriteAction>) {
        self.store = store
    }

    public var body: some View {
        List {
            ForEach(store.value, id: \.self) { prime in
                Text("\(prime)")
                    .swipeActions {
                        Button("Delete") {
                            store.send(.removeFromFavorite(prime))
                        }
                        .tint(.red)
                    }
            }
        }
        .navigationBarTitle("Favorite primes")
        .navigationBarItems(trailing: HStack {
            Button {
                self.store.send(.saveButtonTapped)
            } label: {
                Text("Save")
            }
            Button {
                let documentsPath = NSSearchPathForDirectoriesInDomains(
                    .documentDirectory, .userDomainMask, true
                )[0]
                let documentsUrl = URL(fileURLWithPath: documentsPath)
                let favoritePrimesUrl = documentsUrl
                    .appendingPathComponent("favorite-primes.json")
                guard
                    let data = try? Data(contentsOf: favoritePrimesUrl),
                    let favoritePrimes = try? JSONDecoder().decode([Int].self, from: data)
                else { return }
                self.store.send(.loadedFavoritePrimes(favoritePrimes))
            } label: {
                Text("Load")
            }
        })
    }
}
