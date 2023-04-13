//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import Counter
import Combine
import ComposableArchitecture
import SwiftUI

/// お気に入り一覧でのアクション
public enum FavoriteAction: Equatable {
    case removeFromFavorite(Int)
    case loadedFavoritePrimes([Int])
    case saveButtonTapped
    case loadButtonTapped
    case primeButtonTapped(Int)
    case nthPrimeResponse(n: Int, prime: Int?)
    case alertDismissButtonTapped
}

/// FavoriteViewで使うreducer
public func favoriteReducer(value: inout FavoritePrimesState, action: FavoriteAction, environment: FavoritePrimesEnvironment) -> [Effect<FavoriteAction>] {
    switch action {
    case .removeFromFavorite(let number):
        value.favoritePrimes.removeAll(where: { $0 == number })
        return []
    case .loadedFavoritePrimes(let favoritePrimes):
        value.favoritePrimes = favoritePrimes
        return []
    case .saveButtonTapped:
        return [
            environment.fileClient
                .save("favorite-primes.json", try! JSONEncoder().encode(value.favoritePrimes))
                .fireAndForget()
        ]
    case .loadButtonTapped:
        return [
            environment.fileClient
                .load("favorite-primes.json")
                .compactMap { $0 }
                .decode(type: [Int].self, decoder: JSONDecoder())
                .catch { _ in Empty(completeImmediately: true) }
                .map(FavoriteAction.loadedFavoritePrimes)
                .eraseToEffect()
        ]
    case let .primeButtonTapped(prime):
        return [
            environment.nthPrime(prime)
                .map { FavoriteAction.nthPrimeResponse(n: prime, prime: $0) }
                .receive(on: DispatchQueue.main)
                .eraseToEffect()
        ]
    case let .nthPrimeResponse(n, prime):
        value.alertNthPrime = prime.map { PrimeAlert(n: n, prime: $0) }
        return []
    case .alertDismissButtonTapped:
        value.alertNthPrime = nil
        return []
    }
}

public typealias FavoritePrimesEnvironment = (fileClient: FileClient, nthPrime: (Int) -> Effect<Int?>)

public struct FavoritePrimesState: Equatable {
    public var alertNthPrime: PrimeAlert?
    public var favoritePrimes: [Int]

    public init(alertNthPrime: PrimeAlert? = nil, favoritePrimes: [Int]) {
        self.alertNthPrime = alertNthPrime
        self.favoritePrimes = favoritePrimes
    }
}

public struct FileClient {
    var load: (String) -> Effect<Data?>
    var save: (String, Data) -> Effect<Never>
}

extension FileClient {

    public static let live = FileClient(
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

    let store: Store<FavoritePrimesState, FavoriteAction>
    @ObservedObject var viewStore: ViewStore<FavoritePrimesState>

    public init(store: Store<FavoritePrimesState, FavoriteAction>) {
        self.store = store
        self.viewStore = store.view
    }

    public var body: some View {
        List {
            ForEach(viewStore.value.favoritePrimes, id: \.self) { prime in
                Button {
                    store.send(.primeButtonTapped(prime))
                } label: {
                    Text("\(prime)")
                }
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
        .alert(
            item: .constant(self.store.value.alertNthPrime)
        ) { alert in
            Alert(
                title: Text(alert.title),
                dismissButton: .default(Text("Ok")) {
                    self.store.send(.alertDismissButtonTapped)
                }
            )
        }
    }
}

#if DEBUG
extension FileClient {
    public static let mock = FileClient(
        load: { _ in Effect<Data?>.sync { try! JSONEncoder().encode([2, 31]) } },
        save: { _, _ in .fireAndForget {} }
    )
}
#endif
