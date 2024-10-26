import Foundation
import Perception
import SwiftNavigation
import Dependencies
import FactClient

@MainActor
@Perceptible
public class CounterModel: HashableObject {

    @PerceptionIgnored
    @Dependency(FactClient.self) var factClient
    @PerceptionIgnored
    @Dependency(\.continuousClock) var clock

    public var count = 0 {
        didSet {
            isTextFocused = !count.isMultiple(of: 3)
        }
    }

    public var alert: AlertState<Never>?
    //  public var fact: Fact? {
    //    didSet {
    //        print("Fact didset")
    //    }
    //}
    public var factIsLoading = false
    public var isTextFocused = false {
        didSet { print ("textFocused", isTextFocused) }
    }
    public var text = "" {
        didSet { print("text changed", text) }
    }


    private var timerTask: Task<Void, Error>?
    public var isTimerRunning: Bool { timerTask != nil }

  public struct Fact: Identifiable {
    public var value: String
    public var id: String { value }
  }

  public init() {}

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
            ButtonState {
                TextState("OK")
            }
            ButtonState {
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
