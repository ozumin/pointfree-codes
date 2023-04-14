//
//  PrimeTimeTests.swift
//  PrimeTimeTests
//
//  Created by Mizuo Nagayama on 2023/04/09.
//

import ComposableArchitectureTestSupport
import XCTest
@testable import ComposableArchitecture
@testable import FavoritePrimes
@testable import PrimeTime

final class PrimeTimeTests: XCTestCase {

    func testIntegration() {

        var fileClient: FileClient = .mock
        fileClient.load = { _ in
            return Effect<Data?>.sync {
                try! JSONEncoder().encode([2, 31, 7])
            }
        }

        assert(
            initialvalue: AppState(),
            reducer: appReducer,
            environment: (nthPrime: { _ in .sync { 17 } }, offlineNthPrime: { _ in .sync { 17 } }, fileClient: .mock),
            steps:
                Step(.send, .counterView(.counter(.nthPrimeRequest(2)))) {
                    $0.isNthPrimeRequestInFlight = true
                },
            Step(.receive, .counterView(.counter(.nthPrimeResponse(2, 17)))) {
                $0.alertNthPrime = .init(n: 2, prime: 17)
                $0.isNthPrimeRequestInFlight = false
            },
            Step(.send, .counterView(.counter(.alertDismissButtonTapped))) {
                $0.alertNthPrime = nil
            }
        )
    }

}
