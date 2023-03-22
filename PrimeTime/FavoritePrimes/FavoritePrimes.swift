//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import Combine
import ComposableArchitecture
import SwiftUI

/// お気に入り一覧でのアクション
public enum FavoriteAction: Equatable {
    case removeFromFavorite(Int)
    case loadedFavoritePrimes([Int])
    case saveButtonTapped
    case loadButtonTapped
}

/// FavoriteViewで使うreducer
public func favoriteReducer(value: inout [Int], action: FavoriteAction) -> [Effect<FavoriteAction>] {
    switch action {
    case .removeFromFavorite(let number):
        value.removeAll(where: { $0 == number })
        return []
    case .loadedFavoritePrimes(let favoritePrimes):
        value = favoritePrimes
        return []
    case .saveButtonTapped:
        return [
            Current.fileClient
                .save("favorite-primes.json", try! JSONEncoder().encode(value))
                .fireAndForget()
        ]
    case .loadButtonTapped:
        return [
            Current.fileClient
                .load("favorite-primes.json")
                .compactMap { $0 }
                .decode(type: [Int].self, decoder: JSONDecoder())
                .catch { _ in Empty(completeImmediately: true) }
                .map(FavoriteAction.loadedFavoritePrimes)
                .eraseToEffect()
        ]
    }
}

var Current = FavoritePrimesEnvironment.live

struct FavoritePrimesEnvironment {
    var fileClient: FileClient
}

extension FavoritePrimesEnvironment {
    static let live = FavoritePrimesEnvironment(fileClient: .live)
}

struct FileClient {
    var load: (String) -> Effect<Data?>
    var save: (String, Data) -> Effect<Never>
}

extension FileClient {

    static let live = FileClient(
        load: { fileName in
                .sync {
                    let documentsPath = NSSearchPathForDirectoriesInDomains(
                        .documentDirectory, .userDomainMask, true
                    )[0]
                    let documentsUrl = URL(fileURLWithPath: documentsPath)
                    let favoritePrimesUrl = documentsUrl
                        .appendingPathComponent(fileName)
                    return try? Data(contentsOf: favoritePrimesUrl)
                }
        },
        save: { fileName, data in
                .fireAndForget {
                    let documentsPath = NSSearchPathForDirectoriesInDomains(
                        .documentDirectory, .userDomainMask, true
                    )[0]
                    let documentsUrl = URL(fileURLWithPath: documentsPath)
                    let favoritePrimesUrl = documentsUrl
                        .appendingPathComponent(fileName)
                    try! data.write(to: favoritePrimesUrl)
                }
        }
    )
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
                self.store.send(.loadButtonTapped)
            } label: {
                Text("Load")
            }
        })
    }
}

#if DEBUG
extension FavoritePrimesEnvironment {
    static let mock = FavoritePrimesEnvironment(
        fileClient: .init(
            load: { _ in Effect<Data?>.sync { try! JSONEncoder().encode([2, 31]) } },
            save: { _, _ in .fireAndForget {} }
        )
    )
}
#endif
