//
//  Counter.swift
//  
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import ComposableArchitecture
import PrimeModal
import SwiftUI

/// カウンターでのアクション
public enum CounterAction: Equatable {
    case increaseNumber
    case decreaseNumber
    case nthPrimeRequest(Int)
    case nthPrimeResponse(Int, Int?)
    case alertDismissButtonTapped
    case primeDetailDismissed
    case isPrimeButtonTapped
}

public typealias CounterState = (
    alertNthPrime: PrimeAlert?,
    targetNumber: Int,
    isNthPrimeButtonDisabled: Bool,
    isPrimeDetailShown: Bool
)

public struct PrimeAlert: Equatable, Identifiable {
    public let n: Int
    public let prime: Int
    public var id: Int { self.prime }

    public init(n: Int, prime: Int) {
        self.n = n
        self.prime = prime
    }

    public var title: String {
        return "The \(n)th prime is \(prime)"
    }
}

public let counterViewReducer: Reducer<CounterFeatureState, CounterFeatureAction, CounterEnvironment> = Reducer.combine(
    counterReducer.pullback(value: \CounterFeatureState.counter, action: \.counter, environment: { $0 }),
    primeResultReducer.pullback(value: \.primeModal, action: \.primeResult, environment: { _ in })
)

/// CounterViewでのreducer
public let counterReducer = Reducer<CounterState, CounterAction, CounterEnvironment> {value, action, environment in
    switch action {
    case .decreaseNumber:
        value.targetNumber -= 1
        return []
    case .increaseNumber:
        value.targetNumber += 1
        return []
    case .nthPrimeRequest(let n):
        value.isNthPrimeButtonDisabled = true
        return [
            environment(value.targetNumber)
                .map { CounterAction.nthPrimeResponse(n, $0) }
                .receive(on: DispatchQueue.main)
                .eraseToEffect()
        ]
    case let .nthPrimeResponse(n, prime):
        value.alertNthPrime = prime.map { PrimeAlert.init(n: n, prime: $0) }
        value.isNthPrimeButtonDisabled = false
        return []
    case .alertDismissButtonTapped:
        value.alertNthPrime = nil
        return []
    case .primeDetailDismissed:
        value.isPrimeDetailShown = false
        return []
    case .isPrimeButtonTapped:
        value.isPrimeDetailShown = true
        return []
    }
}

public struct CounterFeatureState: Equatable {
    public var alertNthPrime: PrimeAlert?
    public var targetNumber: Int
    public var favoritePrimes: [Int]
    public var isNthPrimeRequestInFlight: Bool
    public var isPrimeDetailShown: Bool

    public init(
        alertNthPrime: PrimeAlert? = nil,
        targetNumber: Int = 0,
        favoritePrimes: [Int] = [],
        isNthPrimeRequestInFlight: Bool = false,
        isPrimeDetailShown: Bool = false
    ) {
        self.alertNthPrime = alertNthPrime
        self.targetNumber = targetNumber
        self.favoritePrimes = favoritePrimes
        self.isNthPrimeRequestInFlight = isNthPrimeRequestInFlight
        self.isPrimeDetailShown = isPrimeDetailShown
    }

    var counter: CounterState {
        get { (self.alertNthPrime, self.targetNumber, self.isNthPrimeRequestInFlight, self.isPrimeDetailShown) }
        set { (self.alertNthPrime, self.targetNumber, self.isNthPrimeRequestInFlight, self.isPrimeDetailShown) = newValue }
    }

    var primeModal: PrimeModalState {
        get { (self.targetNumber, self.favoritePrimes) }
        set { (self.targetNumber, self.favoritePrimes) = newValue }
    }
}

public enum CounterFeatureAction: Equatable {
    case counter(CounterAction)
    case primeResult(PrimeResultAction)

    /// enumでKeyPathを取得するためのワークアラウンド
    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
        }
    }

    /// enumでKeyPathを取得するためのワークアラウンド
    var primeResult: PrimeResultAction? {
        get {
            guard case let .primeResult(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeResult = self, let newValue = newValue else { return }
            self = .primeResult(newValue)
        }
    }
}

public typealias CounterEnvironment = (Int) -> Effect<Int?>

import Combine
public func offlineNthPrime(_ n: Int) -> Effect<Int?> {
    Future { callback in
        var nthPrime = 1
        var count = 0
        while count <= n {
            nthPrime += 1
            if isPrime(nthPrime) {
                count += 1
            }
        }
        callback(.success(nthPrime))
    }
    .eraseToEffect()
}
