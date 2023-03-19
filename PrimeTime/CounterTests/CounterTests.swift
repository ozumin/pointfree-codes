//
//  CounterTests.swift
//  CounterTests
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import XCTest
@testable import Counter

final class CounterTests: XCTestCase {

    func testIncreaseNumber() throws {
        var store = CounterViewState(
            alertNthPrime: nil,
            targetNumber: 2,
            favoritePrimes: [],
            isNthPrimeButtonDisabled: false
        )

        let effects = counterViewReducer(&store, .counter(.increaseNumber))

        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: nil,
                targetNumber: 3,
                favoritePrimes: [],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)
    }

    func testDecreaseNumber() throws {
        var store = CounterViewState(
            alertNthPrime: nil,
            targetNumber: 2,
            favoritePrimes: [],
            isNthPrimeButtonDisabled: false
        )

        let effects = counterViewReducer(&store, .counter(.decreaseNumber))

        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: nil,
                targetNumber: 1,
                favoritePrimes: [],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)
    }

    func testNthPrimeButtonSuccessFlow() throws {
        var store = CounterViewState(
            alertNthPrime: nil,
            targetNumber: 2,
            favoritePrimes: [],
            isNthPrimeButtonDisabled: false
        )

        // tap button
        var effects = counterViewReducer(&store, .counter(.nthPrimeButtonTapped))

        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: nil,
                targetNumber: 2,
                favoritePrimes: [],
                isNthPrimeButtonDisabled: true
            )
        )
        XCTAssertEqual(effects.count, 1)

        // API response
        effects = counterViewReducer(&store, .counter(.nthPrimeResponse(3)))
        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: .init(prime: 3),
                targetNumber: 2,
                favoritePrimes: [],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)

        // tap dimiss button
        effects = counterViewReducer(&store, .counter(.alertDismissButtonTapped))
        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: nil,
                targetNumber: 2,
                favoritePrimes: [],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)
    }

    func testNthPrimeButtonUnsuccessFlow() throws {
        var store = CounterViewState(
            alertNthPrime: nil,
            targetNumber: 2,
            favoritePrimes: [],
            isNthPrimeButtonDisabled: false
        )

        // tap button
        var effects = counterViewReducer(&store, .counter(.nthPrimeButtonTapped))

        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: nil,
                targetNumber: 2,
                favoritePrimes: [],
                isNthPrimeButtonDisabled: true
            )
        )
        XCTAssertEqual(effects.count, 1)

        // API response
        effects = counterViewReducer(&store, .counter(.nthPrimeResponse(nil)))
        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: nil,
                targetNumber: 2,
                favoritePrimes: [],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)

        // tap dimiss button
        effects = counterViewReducer(&store, .counter(.alertDismissButtonTapped))
        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: nil,
                targetNumber: 2,
                favoritePrimes: [],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)
    }

    func testPrimeModal() throws {
        var store = CounterViewState(
            alertNthPrime: nil,
            targetNumber: 2,
            favoritePrimes: [],
            isNthPrimeButtonDisabled: false
        )
        var effects = counterViewReducer(&store, .primeResult(.addToFavorite))

        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: nil,
                targetNumber: 2,
                favoritePrimes: [2],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)

        effects = counterViewReducer(&store, .primeResult(.removeFromFavorite))

        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: nil,
                targetNumber: 2,
                favoritePrimes: [],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)
    }
}
