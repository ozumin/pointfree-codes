//
//  ComposableArchitectureTestSupport.swift
//  CounterTests
//
//  Created by Mizuo Nagayama on 2023/03/23.
//

import Combine
import ComposableArchitecture
import Foundation
import XCTest

public struct Step<Value, Action> {

    public enum StepType {
        case send
        case receive
    }

    let type: StepType
    let action: Action
    let file: StaticString
    let line: UInt
    let update: (inout Value) -> Void

    public init(_ type: StepType, _ action: Action, file: StaticString = #file, line: UInt = #line, _ update: @escaping (inout Value) -> Void) {
        self.type = type
        self.action = action
        self.file = file
        self.line = line
        self.update = update
    }
}

public func assert<Value: Equatable, Action: Equatable, Environment>(
    initialvalue: Value,
    reducer: Reducer<Value, Action, Environment>,
    environment: Environment,
    steps: Step<Value, Action>...,
    file: StaticString = #file,
    line: UInt = #line
) {
    var state = initialvalue
    var effects: [Effect<Action>] = []
    var cancellables: [AnyCancellable] = []

    steps.forEach { step in
        var expected = state

        switch step.type {
        case .send:
            if effects.isEmpty == false {
                XCTFail("Action sent before handling \(effects.count) pending effect(s)", file: step.file, line: step.line)
            }
            effects.append(contentsOf: reducer(&state, step.action, environment))
        case .receive:
            guard effects.isEmpty == false else {
                XCTFail("No pending effects to receive from", file: step.file, line: step.line)
                break
            }

            let effect = effects.removeFirst()
            var action: Action!
            let receivedCompletion = XCTestExpectation(description: "receivedCompletion")
            cancellables.append(
                effect.sink(
                    receiveCompletion: { _ in
                        receivedCompletion.fulfill()
                    },
                    receiveValue: { action = $0 }
                )
            )
            if XCTWaiter().wait(for: [receivedCompletion], timeout: 1) != .completed {
                XCTFail("Timed out waiting for the effect to complete", file: step.file, line: step.line)
            }
            XCTAssertEqual(action, step.action, file: step.file, line: step.line)
            effects.append(contentsOf: reducer(&state, action, environment))
        }

        step.update(&expected)
        XCTAssertEqual(state, expected, file: step.file, line: step.line)
    }
    if effects.isEmpty == false {
        XCTFail("Assertion failed to handle \(effects.count) pending effect(s)", file: file, line: line)
    }
}
