import SwiftUI
import PlaygroundSupport
import ComposableArchitecture
@testable import Counter

PlaygroundPage.current.setLiveView(
    CounterView(
        store: Store<CounterFeatureState, CounterFeatureAction>(
            value: CounterFeatureState(
                alertNthPrime: nil,
                targetNumber: 3,
                favoritePrimes: [1,2,3],
                isNthPrimeRequestInFlight: false
            ),
            reducer: counterViewReducer,
            environment: { _ in .sync { 17 } }
        )
    )
)
