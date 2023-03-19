//
//  PrimeModalTests.swift
//  PrimeModalTests
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import XCTest
@testable import PrimeModal

final class PrimeModalTests: XCTestCase {

    func testAddToFavorite() throws {
        var store: PrimeModalState = (targetNumber: 2, favoritePrimes: [])
        let effects = primeResultReducer(value: &store, action: .addToFavorite)
        XCTAssertEqual(store.targetNumber, 2)
        XCTAssertEqual(store.favoritePrimes, [2])
        XCTAssert(effects.isEmpty)
    }

    func testRemoveFromFavorite() throws {
        var store: PrimeModalState = (targetNumber: 2, favoritePrimes: [2])
        let effects = primeResultReducer(value: &store, action: .removeFromFavorite)
        XCTAssertEqual(store.targetNumber, 2)
        XCTAssertEqual(store.favoritePrimes, [])
        XCTAssert(effects.isEmpty)
    }
}
