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
        let effects = favoriteReducer(value: &store, action: .removeFromFavorite(3), environment: .mock)
        XCTAssertEqual(store, [2, 5])
        XCTAssert(effects.isEmpty)
    }

    func testSaveButtonTapped() throws {
        var didSave = false

        var store = [2, 3, 5]
        let effects = favoriteReducer(
            value: &store,
            action: .saveButtonTapped,
            environment: .init(load: { _ in .sync { nil } }, save: { _, _ in .fireAndForget { didSave = true } })
        )
        XCTAssertEqual(store, [2, 3, 5])
        XCTAssertEqual(effects.count, 1)

        _ = effects[0].sink { _ in XCTFail() }
        XCTAssert(didSave)
    }

    func testLoadButtonTapped() throws {
        var store = [2, 3, 5]
        var effects = favoriteReducer(value: &store, action: .loadButtonTapped, environment: .mock)
        XCTAssertEqual(store, [2, 3, 5])
        XCTAssertEqual(effects.count, 1)

        var nextAction: FavoriteAction!
        let receivedCompletion = self.expectation(description: "receivedCompletion")
        _ = effects[0]
            .sink(
                receiveCompletion: { _ in
                    receivedCompletion.fulfill()
                },
                receiveValue: { action in
                    XCTAssertEqual(action, .loadedFavoritePrimes([2, 31]))
                    nextAction = action
                }
            )
        self.wait(for: [receivedCompletion], timeout: 0)
        effects = favoriteReducer(value: &store, action: nextAction, environment: .mock)
        XCTAssertEqual(store, [2, 31])
        XCTAssert(effects.isEmpty)
    }
}
