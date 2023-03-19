//
//  FavoritePrimesTests.swift
//  FavoritePrimesTests
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import XCTest
@testable import FavoritePrimes

final class FavoritePrimesTests: XCTestCase {

    func testRemoveFromFavorite() throws {
        var store = [2, 3, 5]
        let effects = favoriteReducer(value: &store, action: .removeFromFavorite(3))
        XCTAssertEqual(store, [2, 5])
        XCTAssert(effects.isEmpty)
    }

    func testSaveButtonTapped() throws {
        var store = [2, 3, 5]
        let effects = favoriteReducer(value: &store, action: .saveButtonTapped)
        XCTAssertEqual(store, [2, 3, 5])
        XCTAssertEqual(effects.count, 1)
    }

    func testLoadButtonTapped() throws {
        var store = [2, 3, 5]
        let effects = favoriteReducer(value: &store, action: .loadButtonTapped)
        XCTAssertEqual(store, [2, 3, 5])
        XCTAssertEqual(effects.count, 1)
    }

    func testLoadedFavoritePrimes() throws {
        var store = [5]
        let effects = favoriteReducer(value: &store, action: .loadedFavoritePrimes([2, 3, 5]))
        XCTAssertEqual(store, [2, 3, 5])
        XCTAssert(effects.isEmpty)
    }
}
