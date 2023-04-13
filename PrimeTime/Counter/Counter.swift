//
//  Counter.swift
//  
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import ComposableArchitecture
import PrimeModal
import SwiftUI

/// カウンターでのアクション
public enum CounterAction: Equatable {
    case increaseNumber
    case decreaseNumber
    case nthPrimeButtonTapped(Int)
    case nthPrimeResponse(Int, Int?)
    case alertDismissButtonTapped
}

public typealias CounterState = (
    alertNthPrime: PrimeAlert?,
    targetNumber: Int,
    isNthPrimeButtonDisabled: Bool
)

public struct PrimeAlert: Equatable, Identifiable {
    public let n: Int
    public let prime: Int
    public var id: Int { self.prime }

    public init(n: Int, prime: Int) {
        self.n = n
        self.prime = prime
    }

    public var title: String {
        return "The \(n)th prime is \(prime)"
    }
}

public let counterViewReducer: Reducer<CounterFeatureState, CounterFeatureAction, CounterEnvironment> = combine(
    pullBack(counterReducer, value: \CounterFeatureState.counter, action: \.counter, environment: { $0 }),
    pullBack(primeResultReducer, value: \.primeModal, action: \.primeResult, environment: { _ in })
)

/// CounterViewでのreducer
public func counterReducer(value: inout CounterState, action: CounterAction, environment: CounterEnvironment) -> [Effect<CounterAction>] {
    switch action {
    case .decreaseNumber:
        value.targetNumber -= 1
        return []
    case .increaseNumber:
        value.targetNumber += 1
        return []
    case .nthPrimeButtonTapped(let n):
        value.isNthPrimeButtonDisabled = true
        return [
            environment(value.targetNumber)
                .map { CounterAction.nthPrimeResponse(n, $0) }
                .receive(on: DispatchQueue.main)
                .eraseToEffect()
        ]
    case let .nthPrimeResponse(n, prime):
        value.alertNthPrime = prime.map { PrimeAlert.init(n: n, prime: $0) }
        value.isNthPrimeButtonDisabled = false
        return []
    case .alertDismissButtonTapped:
        value.alertNthPrime = nil
        return []
    }
}

public struct CounterFeatureState: Equatable {
    public var alertNthPrime: PrimeAlert?
    public var targetNumber: Int
    public var favoritePrimes: [Int]
    public var isNthPrimeRequestInFlight: Bool

    public init(
        alertNthPrime: PrimeAlert? = nil,
        targetNumber: Int = 0,
        favoritePrimes: [Int] = [],
        isNthPrimeRequestInFlight: Bool = false
    ) {
        self.alertNthPrime = alertNthPrime
        self.targetNumber = targetNumber
        self.favoritePrimes = favoritePrimes
        self.isNthPrimeRequestInFlight = isNthPrimeRequestInFlight
    }

    var counter: CounterState {
        get { (self.alertNthPrime, self.targetNumber, self.isNthPrimeRequestInFlight) }
        set { (self.alertNthPrime, self.targetNumber, self.isNthPrimeRequestInFlight) = newValue }
    }

    var primeModal: PrimeModalState {
        get { (self.targetNumber, self.favoritePrimes) }
        set { (self.targetNumber, self.favoritePrimes) = newValue }
    }
}

public enum CounterFeatureAction: Equatable {
    case counter(CounterAction)
    case primeResult(PrimeResultAction)

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
}

public typealias CounterEnvironment = (Int) -> Effect<Int?>

/// カウンターのView
public struct CounterView: View {

    struct CounterViewState: Equatable {
        let targetNumber: Int
        let isNthPrimeButtonDisabled: Bool
        let alertNthPrime: PrimeAlert?
        let isIncrementButtonDisabled: Bool
        let isDecrementButtonDisabled: Bool
    }

    let store: Store<CounterFeatureState, CounterFeatureAction>
    @ObservedObject var viewStore: ViewStore<CounterViewState>

    @State var showResultSheet: Bool = false

    public init(store: Store<CounterFeatureState, CounterFeatureAction>) {
        self.store = store
        self.viewStore = store.scope(value: CounterViewState.init(counterFeatureState:), action: { $0 }).view
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack{
                Button {
                    store.send(.counter(.decreaseNumber))
                } label: {
                    Text("-")
                }
                .disabled(self.viewStore.value.isDecrementButtonDisabled)
                Text("\(viewStore.value.targetNumber)")
                Button {
                    store.send(.counter(.increaseNumber))
                } label: {
                    Text("+")
                }
                .disabled(self.viewStore.value.isIncrementButtonDisabled)
            }
            Button {
                showResultSheet = true
            } label: {
                Text("Is this prime?")
            }
            Button {
                self.store.send(.counter(.nthPrimeButtonTapped(viewStore.value.targetNumber)))
            } label: {
                Text("What is the \(viewStore.value.targetNumber)th prime?")
            }
            .disabled(self.viewStore.value.isNthPrimeButtonDisabled)
            Spacer()
        }
        .sheet(isPresented: $showResultSheet) {
            PrimeResultView(
                store: store.scope(
                    value: { $0.primeModal },
                    action: { .primeResult($0) }
                )
            )
        }
        .alert(
            item: .constant(self.viewStore.value.alertNthPrime)
        ) { alert in
            Alert(
                title: Text(alert.title),
                dismissButton: .default(Text("Ok")) {
                    self.store.send(.counter(.alertDismissButtonTapped))
                }
            )
        }
    }
}

extension CounterView.CounterViewState {
    init(counterFeatureState: CounterFeatureState) {
        self.alertNthPrime = counterFeatureState.alertNthPrime
        self.targetNumber = counterFeatureState.targetNumber
        self.isNthPrimeButtonDisabled = counterFeatureState.isNthPrimeRequestInFlight
        self.isIncrementButtonDisabled = counterFeatureState.isNthPrimeRequestInFlight
        self.isDecrementButtonDisabled = counterFeatureState.isNthPrimeRequestInFlight
    }
}

import Combine
public func offlineNthPrime(_ n: Int) -> Effect<Int?> {
    Future { callback in
        var nthPrime = 1
        var count = 0
        while count <= n {
            nthPrime += 1
            if isPrime(nthPrime) {
                count += 1
            }
        }
        callback(.success(nthPrime))
    }
    .eraseToEffect()
}
