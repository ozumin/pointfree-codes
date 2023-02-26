//
//  ComposableArchitecture.swift
//  ComposableArchitecture
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import Combine
import Foundation

public typealias Effect<Action> = () -> Action?

public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]

/// Reducerの必要な部分だけ取り出す関数
/// GlobalValueの一部をLocalValueとして、GlobalActionの一部をLocalActionとしてreducerに渡している
public func pullBack<LocalValue, GlobalValue, GlobalAction, LocalAction>(
    _ localReducer: @escaping Reducer<LocalValue, LocalAction>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return [] }
        let localEffects = localReducer(&globalValue[keyPath: value], localAction)
        return localEffects.map { localEffect in
            return { () -> GlobalAction? in
                guard let localAction = localEffect() else { return nil }
                var globalAction = globalAction
                globalAction[keyPath: action] = localAction
                return globalAction
            }
        }
    }
}

/// Reducerをまとめ上げる関数
public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    return { value, action in
        return reducers.flatMap { $0(&value, action) }
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
        let effects = reducer(&value, action)
        for effect in effects {
            if let action = effect() {
                send(action)
            }
        }
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
                return []
            }
        )
        store.cancellable = self.$value.sink { [weak store] newValue in
            store?.value = toLocalValue(newValue)
        }
        return store
    }
}

public func logging<Value, Action>(
  _ reducer: @escaping Reducer<Value, Action>
) -> Reducer<Value, Action> {
  return { value, action in
    let effects = reducer(&value, action)
    let newValue = value
    return [{
      print("Action: \(action)")
      print("Value:")
      dump(newValue)
      print("---")
      return nil
    }] + effects
  }
}