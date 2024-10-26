import Foundation
import Perception
import SwiftNavigation
import Dependencies
import FactClient
import StorageClient

@MainActor
@Perceptible
public class CounterModel: HashableObject {

    @PerceptionIgnored
    @Dependency(FactClient.self) var factClient
    @PerceptionIgnored
    @Dependency(\.continuousClock) var clock
  @PerceptionIgnored
  @Dependency(StorageClient.self) var storageClient

    public var count = 0 {
        didSet {
            isTextFocused = !count.isMultiple(of: 3)
        }
    }

    public var alert: AlertState<Alert>?
    //  public var fact: Fact? {
    //    didSet {
    //        print("Fact didset")
    //    }
    //}
    public var factIsLoading = false
    public var isTextFocused = false {
        didSet { print ("textFocused", isTextFocused) }
    }
  public var savedFacts: [String] = [] {
    didSet {
      do {
        try storageClient.save(JSONEncoder().encode(savedFacts), to: .savedFactKey)
      } catch {
        // TODO: error handle
      }
    }
  }
    public var text = "" {
        didSet { print("text changed", text) }
    }


    private var timerTask: Task<Void, Error>?
    public var isTimerRunning: Bool { timerTask != nil }

  public enum Alert: Sendable {
    case saveFact(String)
    case confirmDeleteFact(String)
  }

  public struct Fact: Identifiable {
    public var value: String
    public var id: String { value }
  }

  public init() {
    do {
      savedFacts = try JSONDecoder().decode([String].self, from: storageClient.load(.savedFactKey))
    } catch {
      // TODO: error handling
      savedFacts = []
    }
  }

  public func incrementButtonTapped() {
    count += 1
    alert = nil
  }

  public func decrementButtonTapped() {
    count -= 1
      alert = nil
  }

  public func factButtonTapped() async {
      alert = nil
    factIsLoading = true
    defer { factIsLoading = false }

    do {
        try await Task.sleep(for: .seconds(1))
        var count = count
        let fact = try await factClient.fetch(count)
        alert = AlertState {
            TextState("Fact")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
          ButtonState(action: .saveFact(fact)) {
                TextState("Save")
            }
        } message: {
            TextState(fact)
        }
//        try await Task.sleep(for: .seconds(1))
//        self.fact = nil
    } catch {
      // TODO: error handling
    }
  }

  public func handle(alertAction: Alert) {
    switch alertAction {
    case .saveFact(let fact):
      savedFacts.append(fact)
    case .confirmDeleteFact(let fact):
      savedFacts.removeAll(where: { $0 == fact })
    }
  }

  public func deleteFactButtonTapped(fact: String) {
    alert = AlertState {
      TextState("Delete fact?")
    } actions: {
      ButtonState(role: .destructive, action: .confirmDeleteFact(fact)) {
        TextState("Delete")
      }
      ButtonState(role: .cancel) {
        TextState("Cancel")
      }
    } message: {
      TextState(fact)
    }
  }

  public func toggleTimerButtonTapped() {
    timerTask?.cancel()
    if isTimerRunning {
      timerTask = nil
    } else {
      timerTask = Task {
        for await _ in clock.timer(interval: .seconds(1)) {
          count += 1
        }
      }
    }
  }
}

extension String {
  fileprivate static let savedFactKey = "saved-facts"
}
