//
//  CounterTests.swift
//  CounterTests
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import XCTest
@testable import Counter

final class CounterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Current = .mock
    }

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
        Current.nthPrime = { _ in .sync { 17 } }

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

        var nextAction: CounterViewAction!
        let receivedCompletion = self.expectation(description: "receiveCompletion")
        _ = effects[0].sink(
          receiveCompletion: { _ in receivedCompletion.fulfill() },
          receiveValue: { action in
            nextAction = action
            XCTAssertEqual(action, .counter(.nthPrimeResponse(17)))
        })
        self.wait(for: [receivedCompletion], timeout: 0.1)

        // API response
        effects = counterViewReducer(&store, nextAction)
        XCTAssertEqual(
            store,
            CounterViewState(
                alertNthPrime: .init(prime: 17),
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
        Current.nthPrime = { _ in .sync { nil } }

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

        var nextAction: CounterViewAction!
        let receivedCompletion = self.expectation(description: "receiveCompletion")
        _ = effects[0].sink(
            receiveCompletion: { _ in receivedCompletion.fulfill() },
            receiveValue: { action in
                nextAction = action
                XCTAssertEqual(action, .counter(.nthPrimeResponse(nil)))
            }
        )
        self.wait(for: [receivedCompletion], timeout: 0.01)

        // API response
        effects = counterViewReducer(&store, nextAction)

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
