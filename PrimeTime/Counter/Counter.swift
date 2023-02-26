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
public enum CounterAction {
    case increaseNumber
    case decreaseNumber
}

public let counterViewReducer: Reducer<CounterViewState, CounterViewAction> = combine(
    pullBack(counterReducer, value: \.targetNumber, action: \.counter),
    pullBack(primeResultReducer, value: \.self, action: \.primeResult)
)

/// CounterViewでのreducer
public func counterReducer(value: inout Int, action: CounterAction) -> [Effect<CounterAction>] {
    switch action {
    case .decreaseNumber:
        value -= 1
        return []
    case .increaseNumber:
        value += 1
        return []
    }
}

public typealias CounterViewState = (targetNumber: Int, favoritePrimes: [Int])

public enum CounterViewAction {
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
                // TODO
            } label: {
                Text("What is the \(store.value.targetNumber)th prime?")
            }
            Spacer()
        }
        .sheet(isPresented: $showResultSheet) {
            PrimeResultView(store: store.view(
                value: { $0 },
                action: { .primeResult($0) }
            ))
        }
    }
}