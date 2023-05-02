//
//  CounterView_iOS.swift
//  Counter
//
//  Created by Mizuo Nagayama on 2023/04/23.
//

#if os(iOS)
import ComposableArchitecture
import PrimeModal
import SwiftUI

/// カウンターのView
public struct CounterView: View {

    struct CounterViewState: Equatable {
        let targetNumber: Int
        let isNthPrimeButtonDisabled: Bool
        let alertNthPrime: PrimeAlert?
        let isIncrementButtonDisabled: Bool
        let isDecrementButtonDisabled: Bool
        let isPrimeModalShown: Bool
        let nthPrimeButtonTitle: String
    }

    enum Action: Equatable {
        case incrementButtonTapped
        case decrementButtonTapped
        case nthPrimeButtonTapped(Int)
        case alertDismissButtonTapped
        case doubleTapped(Int)
        case primeModalDismissed
        case isPrimeButtonTapped
    }

    let store: Store<CounterFeatureState, CounterFeatureAction>
    @ObservedObject var viewStore: ViewStore<CounterViewState, Action>

    @State var showResultSheet: Bool = false

    public init(store: Store<CounterFeatureState, CounterFeatureAction>) {
        self.store = store
        self.viewStore = store.scope(value: CounterViewState.init, action: { CounterFeatureAction.init($0) }).view
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack{
                Button {
                    viewStore.send(.decrementButtonTapped)
                } label: {
                    Text("-")
                }
                .disabled(self.viewStore.isDecrementButtonDisabled)
                Text("\(viewStore.value.targetNumber)")
                Button {
                    viewStore.send(.incrementButtonTapped)
                } label: {
                    Text("+")
                }
                .disabled(self.viewStore.isIncrementButtonDisabled)
            }
            Button {
                self.viewStore.send(.isPrimeButtonTapped)
            } label: {
                Text("Is this prime?")
            }
            Button {
                self.viewStore.send(.nthPrimeButtonTapped(viewStore.value.targetNumber))
            } label: {
                Text(viewStore.value.nthPrimeButtonTitle)
            }
            .disabled(self.viewStore.isNthPrimeButtonDisabled)
            Spacer()
        }
        .navigationTitle("Counter demo")
        .sheet(
            isPresented: self.viewStore.binding(
                get: \.isPrimeModalShown,
                send: .primeModalDismissed
            )
        ) {
            PrimeResultView(
                store: store.scope(
                    value: { $0.primeModal },
                    action: { .primeResult($0) }
                )
            )
        }
        .alert(
            item: self.viewStore.binding(
                get: \.alertNthPrime,
                send: .alertDismissButtonTapped
            )
        ) { alert in
            Alert(
                title: Text(alert.title),
                dismissButton: .default(Text("Ok")) {
                    self.viewStore.send(.alertDismissButtonTapped)
                }
            )
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(.white)
        .onTapGesture(count: 2) {
            self.viewStore.send(.doubleTapped(viewStore.value.targetNumber))
        }
    }
}

extension CounterView.CounterViewState {
    init(_ counterFeatureState: CounterFeatureState) {
        self.alertNthPrime = counterFeatureState.alertNthPrime
        self.targetNumber = counterFeatureState.targetNumber
        self.isNthPrimeButtonDisabled = counterFeatureState.isNthPrimeRequestInFlight
        self.isIncrementButtonDisabled = counterFeatureState.isNthPrimeRequestInFlight
        self.isDecrementButtonDisabled = counterFeatureState.isNthPrimeRequestInFlight
        self.isPrimeModalShown = false
        self.nthPrimeButtonTitle = "What is the \(counterFeatureState.targetNumber)th prime?"
    }
}

extension CounterFeatureAction {
    init(_ counterViewAction: CounterView.Action) {
        switch counterViewAction {
        case .alertDismissButtonTapped:
            self = .counter(.alertDismissButtonTapped)
        case .decrementButtonTapped:
            self = .counter(.decreaseNumber)
        case .incrementButtonTapped:
            self = .counter(.increaseNumber)
        case .doubleTapped(let n):
            self = .counter(.nthPrimeRequest(n))
        case .nthPrimeButtonTapped(let n):
            self = .counter(.nthPrimeRequest(n))
        case .primeModalDismissed:
            self = .counter(.primeDetailDismissed)
        case .isPrimeButtonTapped:
            self = .counter(.isPrimeButtonTapped)
        }
    }
}
#endif
