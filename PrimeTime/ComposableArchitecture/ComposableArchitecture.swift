//
//  ComposableArchitecture.swift
//  ComposableArchitecture
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import Foundation

/// Reducerの必要な部分だけ取り出す関数
/// GlobalValueの一部をLocalValueとして、GlobalActionの一部をLocalActionとしてreducerに渡している
public func pullBack<LocalValue, GlobalValue, GlobalAction, LocalAction>(
    _ localReducer: @escaping (inout LocalValue, LocalAction) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> Void {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        localReducer(&globalValue[keyPath: value], localAction)
    }
}

/// Reducerをまとめ上げる関数
public func combine<Value, Action>(
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    return { value, action in
        for reducer in reducers {
            reducer(&value, action)
        }
    }
}

/// Actionを元にValueを書き換えるためのストア
public final class Store<Value, Action>: ObservableObject {

    let reducer: (inout Value, Action) -> Void
    @Published public private(set) var value: Value

    public init(value: Value, reducer: @escaping (inout Value, Action) -> Void) {
        self.reducer = reducer
        self.value = value
    }

    public func send(_ action: Action) {
        reducer(&value, action)
    }
}
