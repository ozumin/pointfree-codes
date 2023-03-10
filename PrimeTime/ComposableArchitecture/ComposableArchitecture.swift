//
//  ComposableArchitecture.swift
//  ComposableArchitecture
//
//  Created by Mizuo Nagayama on 2023/02/04.
//

import Combine
import Foundation

public struct Effect<Output>: Publisher {
    public typealias Failure = Never
    let publisher: AnyPublisher<Output, Failure>

    public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
        self.publisher.receive(subscriber: subscriber)
    }
}

extension Effect {
    public static func fireAndForget(work: @escaping () -> Void) -> Effect {
        return Deferred { () -> Empty<Output, Never> in
            work()
            return Empty(completeImmediately: true)
        }
        .eraseToEffect()
    }

    public static func sync(work: @escaping () -> Output) -> Effect {
        return Deferred {
            Just(work())
        }
        .eraseToEffect()
    }
}

extension Publisher where Failure == Never {

    public func eraseToEffect() -> Effect<Output> {
        return Effect(publisher: self.eraseToAnyPublisher())
    }
}

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
            localEffect
                .map { localAction in
                    var globalAction = globalAction
                    globalAction[keyPath: action] = localAction
                    return globalAction
                }
                .eraseToEffect()
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
    private var viewCancellable: Cancellable?
    private var effectCancellables: Set<AnyCancellable> = []

    public init(value: Value, reducer: @escaping Reducer<Value, Action>) {
        self.reducer = reducer
        self.value = value
    }

    public func send(_ action: Action) {
        let effects = reducer(&value, action)
        effects.forEach { effect in
            var effectCancellable: AnyCancellable!
            var didComplete = false
            effectCancellable = effect.sink(
                receiveCompletion: { [weak self] _ in
                    didComplete = true
                    guard let effectCancellable else { return }
                    self?.effectCancellables.remove(effectCancellable)
                },
                receiveValue: self.send
            )
            if didComplete == false, let effectCancellable {
                self.effectCancellables.insert(effectCancellable)
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
        store.viewCancellable = self.$value.sink { [weak store] newValue in
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
        return [
            .fireAndForget {
                print("Action: \(action)")
                print("Value:")
                dump(newValue)
                print("---")
            }
        ] + effects
    }
}
