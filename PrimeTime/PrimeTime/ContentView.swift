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
struct AppState {
    var targetNumber: Int = 0
    var favoritePrimes: [Int] = []
    var loggedInUser: User? = nil
    var activityFeed: [Activity] = []
    var alertNthPrime: PrimeAlert? = nil
    var isNthPrimeButtonDisabled: Bool = false

    struct Activity {
        let timestamp: Date
        let type: ActivityType

        enum ActivityType {
            case addedFavoritePrime(Int)
            case removedFavoritePrime(Int)
        }
    }

    struct User {
        let id: Int
        let name: String
        let bio: String
    }
}

extension AppState {

    /// これによってpullBack()で使うkeyPathが取得できる
    var favoritePrimesState: [Int] {
        get {
            favoritePrimes
        }
        set {
            favoritePrimes = newValue
        }
    }

    var counterViewState: CounterViewState {
        get {
            CounterViewState(alertNthPrime: alertNthPrime, targetNumber: targetNumber, favoritePrimes: favoritePrimes, isNthPrimeButtonDisabled: isNthPrimeButtonDisabled)
        }
        set {
            targetNumber = newValue.targetNumber
            favoritePrimes = newValue.favoritePrimes
            alertNthPrime = newValue.alertNthPrime
            isNthPrimeButtonDisabled = newValue.isNthPrimeButtonDisabled
        }
    }
}

/// アプリ全体のアクション
enum AppAction {
    case counterView(CounterViewAction)
    case favorite(FavoriteAction)

    /// enumでKeyPathを取得するためのワークアラウンド
    var counterView: CounterViewAction? {
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
    fileClient: FileClient
)

func activityFeed(_ reducer: @escaping Reducer<AppState, AppAction, AppEnvironment>) -> Reducer<AppState, AppAction, AppEnvironment> {
    { value, action, environment in
        switch action {
        case
                .counterView(.counter(_)),
                .favorite(.loadedFavoritePrimes(_)),
                .favorite(.saveButtonTapped),
                .favorite(.loadButtonTapped):
            break
        case .counterView(.primeResult(.addToFavorite)):
            value.activityFeed.append(.init(timestamp: .now, type: .addedFavoritePrime(value.targetNumber)))
        case .counterView(.primeResult(.removeFromFavorite)):
            value.activityFeed.append(.init(timestamp: .now, type: .removedFavoritePrime(value.targetNumber)))
        case let .favorite(.removeFromFavorite(number)):
            value.activityFeed.append(.init(timestamp: .now, type: .removedFavoritePrime(number)))
        }
        return reducer(&value, action, environment)
    }
}

/// アプリで使うreducer
let appReducer: Reducer<AppState, AppAction, AppEnvironment> = combine(
    pullBack(counterViewReducer, value: \.counterViewState, action: \.counterView, environment: { $0.nthPrime }),
    pullBack(favoriteReducer, value: \.favoritePrimesState, action: \.favorite, environment: { $0.fileClient })
)

/// 大元のView
struct ContentView: View {

    @ObservedObject var store: Store<AppState, AppAction>

    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    CounterView(store: store.view(
                        value: { $0.counterViewState },
                        action: { .counterView($0) }
                    ))
                } label: {
                    Text("Counter demo")
                }
                NavigationLink {
                    FavoritesView(store: store.view(
                        value: { $0.favoritePrimesState },
                        action: { .favorite($0) }
                    ))
                } label: {
                    Text("Favorite primes")
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
                reducer: logging(activityFeed(appReducer)),
                environment: AppEnvironment(nthPrime: nthPrime, fileClient: .live)
            )
        )
    }
}
