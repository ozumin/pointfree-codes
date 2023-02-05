//
//  Counter.swift
//  
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import Foundation

/// カウンターでのアクション
public enum CounterAction {
    case increaseNumber
    case decreaseNumber
}

/// CounterViewでのreducer
public func counterReducer(value: inout Int, action: CounterAction) -> Void {
    switch action {
    case .decreaseNumber:
        value -= 1
    case .increaseNumber:
        value += 1
    }
}
