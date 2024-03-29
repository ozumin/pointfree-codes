//
//  ContentView.swift
//  PrimeTime
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import ComposableArchitecture
import Counter
import FavoritePrimes
import SwiftUI

/// アプリの状態
struct AppState: Equatable {
    var targetNumber: Int = 0
    var favoritePrimes: [Int] = []
    var loggedInUser: User? = nil
    var activityFeed: [Activity] = []
    var alertNthPrime: PrimeAlert? = nil
    var isNthPrimeRequestInFlight: Bool = false

    struct Activity: Equatable {
        let timestamp: Date
        let type: ActivityType

        enum ActivityType: Equatable {
            case addedFavoritePrime(Int)
            case removedFavoritePrime(Int)
        }
    }

    struct User: Equatable {
        let id: Int
        let name: String
        let bio: String
    }
}

extension AppState {

    /// これによってpullBack()で使うkeyPathが取得できる
    var favoritePrimesState: FavoritePrimesState {
        get {
            .init(alertNthPrime: alertNthPrime, favoritePrimes: favoritePrimes)
        }
        set {
            alertNthPrime = newValue.alertNthPrime
            favoritePrimes = newValue.favoritePrimes
        }
    }

    var counterViewState: CounterFeatureState {
        get {
            CounterFeatureState(alertNthPrime: alertNthPrime, targetNumber: targetNumber, favoritePrimes: favoritePrimes, isNthPrimeRequestInFlight: isNthPrimeRequestInFlight)
        }
        set {
            targetNumber = newValue.targetNumber
            favoritePrimes = newValue.favoritePrimes
            alertNthPrime = newValue.alertNthPrime
            isNthPrimeRequestInFlight = newValue.isNthPrimeRequestInFlight
        }
    }
}

/// アプリ全体のアクション
enum AppAction: Equatable {
    case counterView(CounterFeatureAction)
    case offlineCounterView(CounterFeatureAction)
    case favorite(FavoriteAction)

    /// enumでKeyPathを取得するためのワークアラウンド
    var counterView: CounterFeatureAction? {
        get {
            guard case let .counterView(value) = self else { return nil }
            return value
        }
        set {
            guard case .counterView = self, let newValue = newValue else { return }
            self = .counterView(newValue)
        }
    }

    /// enumでKeyPathを取得するためのワークアラウンド
    var offlineCounterView: CounterFeatureAction? {
        get {
            guard case let .offlineCounterView(value) = self else { return nil }
            return value
        }
        set {
            guard case .offlineCounterView = self, let newValue = newValue else { return }
            self = .offlineCounterView(newValue)
        }
    }

    /// enumでKeyPathを取得するためのワークアラウンド
    var favorite: FavoriteAction? {
        get {
            guard case let .favorite(value) = self else { return nil }
            return value
        }
        set {
            guard case .favorite = self, let newValue = newValue else { return }
            self = .favorite(newValue)
        }
    }
}

typealias AppEnvironment = (
    nthPrime: (Int) -> Effect<Int?>,
    offlineNthPrime: (Int) -> Effect<Int?>,
    fileClient: FileClient
)

extension Reducer where Value == AppState, Action == AppAction, Environment == AppEnvironment {
    func activityFeed() -> Reducer {
        .init { value, action, environment in
            switch action {
            case
                    .counterView(.counter(_)),
                    .offlineCounterView(.counter(_)),
                    .favorite(.loadedFavoritePrimes(_)),
                    .favorite(.saveButtonTapped),
                    .favorite(.loadButtonTapped),
                    .favorite(.nthPrimeResponse),
                    .favorite(.primeButtonTapped),
                    .favorite(.alertDismissButtonTapped):
                break
            case .counterView(.primeResult(.addToFavorite)), .offlineCounterView(.primeResult(.addToFavorite)):
                value.activityFeed.append(.init(timestamp: .now, type: .addedFavoritePrime(value.targetNumber)))
            case .counterView(.primeResult(.removeFromFavorite)), .offlineCounterView(.primeResult(.removeFromFavorite)):
                value.activityFeed.append(.init(timestamp: .now, type: .removedFavoritePrime(value.targetNumber)))
            case let .favorite(.removeFromFavorite(number)):
                value.activityFeed.append(.init(timestamp: .now, type: .removedFavoritePrime(number)))
            }
            return self(&value, action, environment)
        }
    }
}

/// アプリで使うreducer
let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer.combine(
    counterViewReducer.pullback(value: \.counterViewState, action: \.counterView, environment: { $0.nthPrime }),
    counterViewReducer.pullback(value: \.counterViewState, action: \.offlineCounterView, environment: { $0.offlineNthPrime }),
    favoriteReducer.pullback(value: \.favoritePrimesState, action: \.favorite, environment: { (fileClient: $0.fileClient, nthPrime: nthPrime) })
)

/// 大元のView
struct ContentView: View {

    let store: Store<AppState, AppAction>

    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    CounterView(store: store.scope(
                        value: { $0.counterViewState },
                        action: { .counterView($0) }
                    ))
                } label: {
                    Text("Counter demo")
                }
                NavigationLink {
                    CounterView(store: store.scope(
                        value: { $0.counterViewState },
                        action: { .offlineCounterView($0) }
                    ))
                } label: {
                    Text("Offline counter demo")
                }
                NavigationLink {
                    FavoritesView(store: store.scope(
                        value: { $0.favoritePrimesState },
                        action: { .favorite($0) }
                    ))
                } label: {
                    Text("Favorite primes")
                }
                ForEach(1..<50_000) { number in
                    Text("\(number)")
                }
            }
            .navigationTitle("State management")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store<AppState, AppAction>(
                value: AppState(),
                reducer: appReducer.activityFeed().logging(),
                environment: AppEnvironment(nthPrime: nthPrime, offlineNthPrime: offlineNthPrime, fileClient: .live)
            )
        )
    }
}
