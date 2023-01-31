import SwiftUI
import PlaygroundSupport

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

/// お気に入り一覧で使うstate
struct FavoritePrimesState {

    var favoritePrimes: [Int]
    var activityFeed: [AppState.Activity]
}

extension AppState {

    /// これによってpullBack()で使うkeyPathが取得できる
    var favoritePrimesState: FavoritePrimesState {
        get {
            .init(favoritePrimes: favoritePrimes, activityFeed: activityFeed)
        }
        set {
            favoritePrimes = newValue.favoritePrimes
            activityFeed = newValue.activityFeed
        }
    }
}

/// カウンターでのアクション
enum CounterAction {
    case increaseNumber
    case decreaseNumber
}

/// 素数結果表示時のアクション
enum PrimeResultAction {
    case addToFavorite
    case removeFromFavorite
}

/// お気に入り一覧でのアクション
enum FavoriteAction {
    case removeFromFavorite(Int)
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

/// CounterViewでのreducer
func counterReducer(value: inout Int, action: CounterAction) -> Void {
    switch action {
    case .decreaseNumber:
        value -= 1
    case .increaseNumber:
        value += 1
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

/// PrimeResultViewでのreducer
func primeResultReducer(value: inout AppState, action: PrimeResultAction) -> Void {
    switch action {
    case .addToFavorite:
        value.favoritePrimes.append(value.targetNumber)
    case .removeFromFavorite:
        value.favoritePrimes.removeAll(where: { $0 == value.targetNumber })
    }
}

/// FavoriteViewで使うreducer
func favoriteReducer(value: inout FavoritePrimesState, action: FavoriteAction) -> Void {
    switch action {
    case .removeFromFavorite(let number):
        value.favoritePrimes.removeAll(where: { $0 == number })
    }
}

let _appReducer: (inout AppState, AppAction) -> Void = combine(
    pullBack(counterReducer, value: \.targetNumber, action: \.counter),
    pullBack(primeResultReducer, value: \.self, action: \.primeResult),
    pullBack(favoriteReducer, value: \.favoritePrimesState, action: \.favorite)
)

/// アプリで使うreducer
let appReducer = pullBack(_appReducer, value: \.self, action: \.self)

/// Reducerの必要な部分だけ取り出す関数
/// GlobalValueの一部をLocalValueとして、GlobalActionの一部をLocalActionとしてreducerに渡している
func pullBack<LocalValue, GlobalValue, GlobalAction, LocalAction>(
    _ localReducer: @escaping (inout LocalValue, LocalAction) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> Void {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        localReducer(&globalValue[keyPath: value], localAction)
    }
}

/// Reducerをまとめ上げる関数
func combine<Value, Action>(
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    return { value, action in
        for reducer in reducers {
            reducer(&value, action)
        }
    }
}

/// Actionを元にValueを書き換えるためのストア
final class Store<Value, Action>: ObservableObject {

    let reducer: (inout Value, Action) -> Void
    @Published private(set) var value: Value

    init(value: Value, reducer: @escaping (inout Value, Action) -> Void) {
        self.reducer = reducer
        self.value = value
    }

    func send(_ action: Action) {
        reducer(&value, action)
    }
}

/// カウンターのView
struct CounterView: View {

    @ObservedObject var store: Store<AppState, AppAction>
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
            PrimeResultView(store: store)
        }
    }
}

/// CounterViewでsheet表示する素数の結果のView
struct PrimeResultView: View {

    @ObservedObject var store: Store<AppState, AppAction>

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

    @ObservedObject var store: Store<AppState, AppAction>

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
                    CounterView(store: store)
                } label: {
                    Text("Counter demo")
                }
                NavigationLink {
                    FavoritesView(store: store)
                } label: {
                    Text("Favorite primes")
                }
            }
            .navigationTitle("State management")
        }
    }
}

/// アプリ
PlaygroundPage.current.setLiveView(
    ContentView(
        store: Store<AppState, AppAction>(
            value: AppState(),
            reducer: activityFeed(appReducer)
        )
    )
)
