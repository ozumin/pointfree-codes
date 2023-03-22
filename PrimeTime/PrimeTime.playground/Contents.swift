//: A UIKit based Playground for presenting user interface
  
import SwiftUI
import PlaygroundSupport
import ComposableArchitecture


//import FavoritePrimes
//PlaygroundPage.current.setLiveView(
//    FavoritesView(
//        store: Store<[Int], FavoriteAction>(
//            value: [2,5,7],
//            reducer: favoriteReducer
//        )
//    )
//)

//import PrimeModal
//PlaygroundPage.current.setLiveView(
//    PrimeResultView(
//        store: Store<PrimeModalState, PrimeResultAction>(
//            value: .init(favoritePrimes: [], targetNumber: 3),
//            reducer: primeResultReducer
//        )
//    )
//)

@testable import Counter

Current = .mock

PlaygroundPage.current.setLiveView(
    CounterView(
        store: Store<CounterViewState, CounterViewAction>(
            value: CounterViewState(
                alertNthPrime: nil,
                targetNumber: 3,
                favoritePrimes: [1,2,3],
                isNthPrimeButtonDisabled: false
            ),
            reducer: counterViewReducer
        )
    )
)
