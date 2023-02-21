//
//  ComposableArchitecture.swift
//  ComposableArchitecture
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import Combine
import Foundation

public typealias Effect = () -> Void

public typealias Reducer<Value, Action> = (inout Value, Action) -> Effect

/// Reducerの必要な部分だけ取り出す関数
/// GlobalValueの一部をLocalValueとして、GlobalActionの一部をLocalActionとしてreducerに渡している
public func pullBack<LocalValue, GlobalValue, GlobalAction, LocalAction>(
    _ localReducer: @escaping Reducer<LocalValue, LocalAction>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return {} }
        let effect = localReducer(&globalValue[keyPath: value], localAction)
        return effect
    }
}

/// Reducerをまとめ上げる関数
public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    return { value, action in
        let effects = reducers.map { $0(&value, action) }
        return {
            for effect in effects {
                effect()
            }
        }
    }
}

/// Actionを元にValueを書き換えるためのストア
public final class Store<Value, Action>: ObservableObject {

    let reducer: Reducer<Value, Action>
    @Published public private(set) var value: Value
    private var cancellable: Cancellable?

    public init(value: Value, reducer: @escaping Reducer<Value, Action>) {
        self.reducer = reducer
        self.value = value
    }

    public func send(_ action: Action) {
        let effect = reducer(&value, action)
        effect()
    }

    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let store: Store<LocalValue, LocalAction> = .init(
            value: toLocalValue(self.value),
            reducer: { localValue, localAction in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return {}
            }
        )
        store.cancellable = self.$value.sink { [weak store] newValue in
            store?.value = toLocalValue(newValue)
        }
        return store
    }
}
