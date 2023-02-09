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

/// CounterViewでのreducer
public func counterReducer(value: inout Int, action: CounterAction) -> Void {
    switch action {
    case .decreaseNumber:
        value -= 1
    case .increaseNumber:
        value += 1
    }
}

public typealias CounterViewState = (targetNumber: Int, favoritePrimes: [Int])

public enum CounterViewAction {
    case counter(CounterAction)
    case primeResult(PrimeResultAction)
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
                value: { .init(favoritePrimes: $0.favoritePrimes, targetNumber: $0.targetNumber) },
                action: { .primeResult($0) }
            ))
        }
    }
}
