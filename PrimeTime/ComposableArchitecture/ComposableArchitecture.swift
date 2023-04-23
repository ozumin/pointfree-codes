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

public func absurd<A>(_ never: Never) -> A {}

extension Publisher where Output == Never, Failure == Never {

    public func fireAndForget<A>() -> Effect<A> {
        self.map(absurd).eraseToEffect()
    }
}

public struct Reducer<Value, Action, Environment> {
    let reducer: (inout Value, Action, Environment) -> [Effect<Action>]

    public init(_ reducer: @escaping (inout Value, Action, Environment) -> [Effect<Action>]) {
        self.reducer = reducer
    }
}

extension Reducer {
    public func callAsFunction(_ value: inout Value, _ action: Action, _ environment: Environment) -> [Effect<Action>] {
        self.reducer(&value, action, environment)
    }
}

extension Reducer {
    /// Reducerの必要な部分だけ取り出す関数
    /// GlobalValueの一部をLocalValueとして、GlobalActionの一部をLocalActionとしてreducerに渡している
    public func pullback<GlobalValue, GlobalAction, GlobalEnvironment>(
        value: WritableKeyPath<GlobalValue, Value>,
        action: WritableKeyPath<GlobalAction, Action?>,
        environment: @escaping (GlobalEnvironment) -> Environment
    ) -> Reducer<GlobalValue, GlobalAction, GlobalEnvironment> {
        .init { globalValue, globalAction, globalEnvironment in
            guard let localAction = globalAction[keyPath: action] else { return [] }
            let localEffects = self(&globalValue[keyPath: value], localAction, environment(globalEnvironment))
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
}

extension Reducer {
    /// Reducerをまとめ上げる関数
    public static func combine(_ reducers: Reducer...) -> Reducer {
        .init { value, action, environment in
            return reducers.flatMap { $0(&value, action, environment) }
        }
    }
}

public final class ViewStore<Value, Action>: ObservableObject {
    @Published public fileprivate(set) var value: Value
    fileprivate var cancellable: Cancellable?
    public let send: (Action) -> Void

    public init(initialValue: Value, send: @escaping (Action) -> Void) {
        self.value = initialValue
        self.send = send
    }
}

/// Actionを元にValueを書き換えるためのストア
public final class Store<Value, Action> {

    private let reducer: Reducer<Value, Action, Any>
    private let environment: Any
    @Published public private(set) var value: Value
    private var viewCancellable: Cancellable?
    private var effectCancellables: Set<AnyCancellable> = []

    public init<Environment>(value: Value, reducer: Reducer<Value, Action, Environment>, environment: Environment) {
        self.reducer = .init { value, action, environment in
            reducer(&value, action, environment as! Environment)
        }
        self.value = value
        self.environment = environment
    }

    public func send(_ action: Action) {
        let effects = reducer(&value, action, environment)
        effects.forEach { effect in
            var effectCancellable: AnyCancellable!
            var didComplete = false
            effectCancellable = effect.sink(
                receiveCompletion: { [weak self, weak effectCancellable] _ in
                    didComplete = true
                    guard let effectCancellable else { return }
                    self?.effectCancellables.remove(effectCancellable)
                },
                receiveValue: { [weak self] in self?.send($0) }
            )
            if didComplete == false, let effectCancellable {
                self.effectCancellables.insert(effectCancellable)
            }
        }
    }

    public func scope<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let store: Store<LocalValue, LocalAction> = .init(
            value: toLocalValue(self.value),
            reducer: .init { localValue, localAction, _ in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
            },
            environment: self.environment
        )
        store.viewCancellable = self.$value.sink { [weak store] newValue in
            store?.value = toLocalValue(newValue)
        }
        return store
    }
}

extension Store {
    public func view(removeDuplicates predicate: @escaping (Value, Value) -> Bool) -> ViewStore<Value, Action> {
        let viewStore = ViewStore(initialValue: self.value, send: self.send)
        viewStore.cancellable = self.$value.sink(receiveValue: { [weak viewStore] newValue in
            viewStore?.value = newValue
        })
        return viewStore
    }
}

extension Store where Value: Equatable {
    public var view: ViewStore<Value, Action> {
        self.view(removeDuplicates: ==)
      }
}

extension Reducer {
    public func logging(
        printer: @escaping (Environment) -> (String) -> Void = { _ in { print($0) } }
    ) -> Reducer {
        .init { value, action, environment in
            let effects = self(&value, action, environment)
            let newValue = value
            let print = printer(environment)
            return [
                .fireAndForget {
                    print("Action: \(action)")
                    print("Value:")
                    var dumpedNewValue = ""
                    dump(newValue, to: &dumpedNewValue)
                    print(dumpedNewValue)
                    print("---")
                }
            ] + effects
        }
    }
}
