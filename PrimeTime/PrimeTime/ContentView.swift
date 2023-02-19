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
    var favoritePrimesState: FavoritePrimesState {
        get {
            .init(favoritePrimes: favoritePrimes)
        }
        set {
            favoritePrimes = newValue.favoritePrimes
        }
    }

    var counterViewState: CounterViewState {
        get {
            CounterViewState(targetNumber: targetNumber, favoritePrimes: favoritePrimes)
        }
        set {
            targetNumber = newValue.targetNumber
            favoritePrimes = newValue.favoritePrimes
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

func activityFeed(_ reducer: @escaping (inout AppState, AppAction) -> Void) -> (inout AppState, AppAction) -> Void {
    { value, action in
        switch action {
        case .counterView(.counter(_)):
            break
        case .counterView(.primeResult(.addToFavorite)):
            value.activityFeed.append(.init(timestamp: .now, type: .addedFavoritePrime(value.targetNumber)))
        case .counterView(.primeResult(.removeFromFavorite)):
            value.activityFeed.append(.init(timestamp: .now, type: .removedFavoritePrime(value.targetNumber)))
        case let .favorite(.removeFromFavorite(number)):
            value.activityFeed.append(.init(timestamp: .now, type: .removedFavoritePrime(number)))
        }
        reducer(&value, action)
    }
}

let _appReducer: (inout AppState, AppAction) -> Void = combine(
    pullBack(counterViewReducer, value: \.counterViewState, action: \.counterView),
    pullBack(favoriteReducer, value: \.favoritePrimesState, action: \.favorite)
)

/// アプリで使うreducer
let appReducer = pullBack(_appReducer, value: \.self, action: \.self)

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
                reducer: activityFeed(appReducer)
            )
        )
    }
}
