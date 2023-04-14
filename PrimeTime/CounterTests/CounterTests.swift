//
//  CounterTests.swift
//  CounterTests
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import ComposableArchitectureTestSupport
import XCTest
@testable import Counter

final class CounterTests: XCTestCase {

    func testIncreaseNumber() throws {
        assert(
            initialvalue: CounterFeatureState(targetNumber: 2),
            reducer: counterViewReducer,
            environment: { _ in .sync { 17 } },
            steps:
                Step(.send, .counter(.increaseNumber)) { $0.targetNumber = 3 },
            Step(.send, .counter(.increaseNumber)) { $0.targetNumber = 4 }
        )
    }

    func testDecreaseNumber() throws {
        assert(
            initialvalue: CounterFeatureState(targetNumber: 2),
            reducer: counterViewReducer,
            environment: { _ in .sync { 17 } },
            steps:
                Step(.send, .counter(.decreaseNumber)) { $0.targetNumber = 1 },
            Step(.send, .counter(.decreaseNumber)) { $0.targetNumber = 0 }
        )
    }

    func testNthPrimeButtonSuccessFlow() throws {
        assert(
            initialvalue: CounterFeatureState(alertNthPrime: nil, isNthPrimeRequestInFlight: false),
            reducer: counterViewReducer,
            environment: { _ in .sync { 17 } },
            steps:
                Step(.send, .counter(.nthPrimeRequest(2))) {
                    $0.isNthPrimeRequestInFlight = true
                },
            Step(.receive, .counter(.nthPrimeResponse(2, 17))) {
                $0.alertNthPrime = .init(n: 2, prime: 17)
                $0.isNthPrimeRequestInFlight = false
            },
            Step(.send, .counter(.alertDismissButtonTapped)) {
                $0.alertNthPrime = nil
            }
        )
    }

    func testNthPrimeButtonUnsuccessFlow() throws {
        assert(
            initialvalue: CounterFeatureState(alertNthPrime: nil, isNthPrimeRequestInFlight: false),
            reducer: counterViewReducer,
            environment: { _ in .sync { nil } },
            steps:
                Step(.send, .counter(.nthPrimeRequest(2))) { $0.isNthPrimeRequestInFlight = true },
            Step(.receive, .counter(.nthPrimeResponse(2, nil))) { $0.isNthPrimeRequestInFlight = false },
            Step(.send, .counter(.alertDismissButtonTapped)) { _ in }
        )
    }

    func testPrimeModal() throws {
        assert(
            initialvalue: CounterFeatureState(targetNumber: 2, favoritePrimes: []),
            reducer: counterViewReducer,
            environment: { _ in .sync { 17 } },
            steps:
                Step(.send, .primeResult(.addToFavorite)) { $0.favoritePrimes = [2] },
            Step(.send, .primeResult(.removeFromFavorite)) { $0.favoritePrimes = [] }
        )
    }
}
