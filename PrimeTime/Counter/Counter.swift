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
    case nthPrimeButtonTapped
    case nthPrimeResponse(Int?)
    case alertDismissButtonTapped
}

public typealias CounterState = (
    alertNthPrime: PrimeAlert?,
    targetNumber: Int,
    isNthPrimeButtonDisabled: Bool
)

public struct PrimeAlert: Equatable, Identifiable {
    let prime: Int
    public var id: Int { self.prime }
}

public let counterViewReducer: Reducer<CounterViewState, CounterViewAction> = combine(
    pullBack(counterReducer, value: \CounterViewState.counter, action: \.counter),
    pullBack(primeResultReducer, value: \.primeModal, action: \.primeResult)
)

/// CounterViewでのreducer
public func counterReducer(value: inout CounterState, action: CounterAction) -> [Effect<CounterAction>] {
    switch action {
    case .decreaseNumber:
        value.targetNumber -= 1
        return []
    case .increaseNumber:
        value.targetNumber += 1
        return []
    case .nthPrimeButtonTapped:
        value.isNthPrimeButtonDisabled = true
        return [
            Current.nthPrime(value.targetNumber)
                .map(CounterAction.nthPrimeResponse)
                .receive(on: DispatchQueue.main)
                .eraseToEffect()
        ]
    case let .nthPrimeResponse(prime):
        value.alertNthPrime = prime.map(PrimeAlert.init(prime:))
        value.isNthPrimeButtonDisabled = false
        return []
    case .alertDismissButtonTapped:
        value.alertNthPrime = nil
        return []
    }
}

public struct CounterViewState: Equatable {
    public var alertNthPrime: PrimeAlert?
    public var targetNumber: Int
    public var favoritePrimes: [Int]
    public var isNthPrimeButtonDisabled: Bool

    public init(
        alertNthPrime: PrimeAlert? = nil,
        targetNumber: Int = 0,
        favoritePrimes: [Int] = [],
        isNthPrimeButtonDisabled: Bool = false
      ) {
        self.alertNthPrime = alertNthPrime
        self.targetNumber = targetNumber
        self.favoritePrimes = favoritePrimes
        self.isNthPrimeButtonDisabled = isNthPrimeButtonDisabled
      }

    var counter: CounterState {
        get { (self.alertNthPrime, self.targetNumber, self.isNthPrimeButtonDisabled) }
        set { (self.alertNthPrime, self.targetNumber, self.isNthPrimeButtonDisabled) = newValue }
    }

    var primeModal: PrimeModalState {
        get { (self.targetNumber, self.favoritePrimes) }
        set { (self.targetNumber, self.favoritePrimes) = newValue }
    }
}

public enum CounterViewAction: Equatable {
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

var Current: CounterEnvironment = .live

struct CounterEnvironment {

    var nthPrime: (Int) -> Effect<Int?>
}

extension CounterEnvironment {

    static let live = Self(nthPrime: Counter.nthPrime)
}

/// カウンターのView
public struct CounterView: View {

    @ObservedObject var store: Store<CounterViewState, CounterViewAction>

    @State var showResultSheet: Bool = false

    public init(store: Store<CounterViewState, CounterViewAction>) {
        self.store = store
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
                self.store.send(.counter(.nthPrimeButtonTapped))
            } label: {
                Text("What is the \(store.value.targetNumber)th prime?")
            }
            .disabled(self.store.value.isNthPrimeButtonDisabled)
            Spacer()
        }
        .sheet(isPresented: $showResultSheet) {
            PrimeResultView(
                store: store.view(
                    value: { $0.primeModal },
                    action: { .primeResult($0) }
                )
            )
        }
        .alert(
            item: .constant(self.store.value.alertNthPrime)
        ) { alert in
            Alert(
                title: Text("The \(self.store.value.targetNumber) prime is \(alert.prime)"),
                dismissButton: .default(Text("Ok")) {
                    self.store.send(.counter(.alertDismissButtonTapped))
                }
            )
        }
    }
}

#if DEBUG
extension CounterEnvironment {

    static let mock = Self(nthPrime: { _ in .sync { 17 } })
}
#endif
