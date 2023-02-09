//
//  ContentView.swift
//  PrimeTime
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import ComposableArchitecture
import Counter
import FavoritePrimes
import PrimeModal
import SwiftUI

/// 素数計算用の関数
func isPrime(_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}

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

    var primeModalState: PrimeModalState {
        get {
            .init(favoritePrimes: favoritePrimes, targetNumber: targetNumber)
        }
        set {
            favoritePrimes = newValue.favoritePrimes
        }
    }
}

/// アプリ全体のアクション
enum AppAction {
    case counter(CounterAction)
    case primeResult(PrimeResultAction)
    case favorite(FavoriteAction)

    /// enumでKeyPathを取得するためのワークアラウンド
    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
        }
    }

    /// enumでKeyPathを取得するためのワークアラウンド
    var primeResult: PrimeResultAction? {
        get {
            guard case let .primeResult(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeResult = self, let newValue = newValue else { return }
            self = .primeResult(newValue)
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
        case .counter(_):
            break
        case .primeResult(.addToFavorite):
            value.activityFeed.append(.init(timestamp: .now, type: .addedFavoritePrime(value.targetNumber)))
        case .primeResult(.removeFromFavorite):
            value.activityFeed.append(.init(timestamp: .now, type: .removedFavoritePrime(value.targetNumber)))
        case let .favorite(.removeFromFavorite(number)):
            value.activityFeed.append(.init(timestamp: .now, type: .removedFavoritePrime(number)))
        }
        reducer(&value, action)
    }
}

let _appReducer: (inout AppState, AppAction) -> Void = combine(
    pullBack(counterReducer, value: \.targetNumber, action: \.counter),
    pullBack(primeResultReducer, value: \.primeModalState, action: \.primeResult),
    pullBack(favoriteReducer, value: \.favoritePrimesState, action: \.favorite)
)

/// アプリで使うreducer
let appReducer = pullBack(_appReducer, value: \.self, action: \.self)

typealias CounterViewState = (targetNumber: Int, favoritePrimes: [Int])

/// カウンターのView
struct CounterView: View {

    @ObservedObject var store: Store<CounterViewState, AppAction>
    @State var showResultSheet: Bool = false

    var body: some View {
        VStack {
            Spacer()
            HStack{
                Button {
                    store.send(.counter(.decreaseNumber))
                } label: {
                    Text("-")
                }
                Text("\(store.value.targetNumber)")
                Button {
                    store.send(.counter(.increaseNumber))
                } label: {
                    Text("+")
                }
            }
            Button {
                showResultSheet = true
            } label: {
                Text("Is this prime?")
            }
            Button {
                // TODO
            } label: {
                Text("What is the \(store.value.targetNumber)th prime?")
            }
            Spacer()
        }
        .sheet(isPresented: $showResultSheet) {
            PrimeResultView(store: store.view({ .init(favoritePrimes: $0.favoritePrimes, targetNumber: $0.targetNumber) }))
        }
    }
}

/// CounterViewでsheet表示する素数の結果のView
struct PrimeResultView: View {

    @ObservedObject var store: Store<PrimeModalState, AppAction>

    var body: some View {
        VStack {
            if isPrime(store.value.targetNumber) {
                Text("\(store.value.targetNumber) is prime 🎉")
                if store.value.favoritePrimes.contains(store.value.targetNumber) {
                    Button {
                        store.send(.primeResult(.removeFromFavorite))
                    } label: {
                        Text("Remove from favorite primes")
                    }
                } else {
                    Button {
                        store.send(.primeResult(.addToFavorite))
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

/// お気に入りの素数一覧のView
struct FavoritesView : View {

    @ObservedObject var store: Store<FavoritePrimesState, AppAction>

    var body: some View {
        List {
            ForEach(store.value.favoritePrimes, id: \.self) { prime in
                Text("\(prime)")
                    .swipeActions {
                        Button("Delete") {
                            store.send(.favorite(.removeFromFavorite(prime)))
                        }
                        .tint(.red)
                    }
            }
        }
    }
}

/// 大元のView
struct ContentView: View {

    @ObservedObject var store: Store<AppState, AppAction>

    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    CounterView(store: store.view({ ($0.targetNumber, $0.favoritePrimes) }))
                } label: {
                    Text("Counter demo")
                }
                NavigationLink {
                    FavoritesView(store: store.view({ .init(favoritePrimes: $0.favoritePrimes) }))
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
