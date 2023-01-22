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
}

/// アプリで使う reducer
func appReducer(value: inout AppState, action: AppAction) -> Void {
    switch action {
    case .counter(let counterAction):
        switch counterAction {
        case .decreaseNumber:
            value.targetNumber -= 1
        case .increaseNumber:
            value.targetNumber += 1
        }
    case .primeResult(let primeResultAction):
        switch primeResultAction {
        case .addToFavorite:
            value.favoritePrimes.append(value.targetNumber)
        case .removeFromFavorite:
            value.favoritePrimes.removeAll(where: { $0 == value.targetNumber })
        }
    case .favorite(let favoriteAction):
        switch favoriteAction {
        case .removeFromFavorite(let number):
            value.favoritePrimes.removeAll(where: { $0 == number })
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
                Text("What is the 0th prime?")
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
PlaygroundPage.current.setLiveView(ContentView(store: Store<AppState, AppAction>(value: AppState(), reducer: appReducer)))
