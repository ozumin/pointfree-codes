//
//  App.swift
//  Counter
//
//  Created by Mizuo Nagayama on 2024/09/15.
//

import Counter
import FactClientLive
import JavaScriptEventLoop
import JavaScriptKit
import SwiftNavigation
import IssueReporting

struct JavaScriptConsoleWarning: IssueReporter {
    func reportIssue(
        _ message: @autoclosure () -> String?,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
    ) {
        #if DEBUG
        _ = JSObject.global.console.warn("""
        \(fileID):\(line) - \(message() ?? "")
        """)
        #endif
    }
}

@main
@MainActor
struct App {
    static var tokens: Set<ObserveToken> = []

    static func main() {
        IssueReporters.current = [JavaScriptConsoleWarning()]

        JavaScriptEventLoop.installGlobalExecutor()

        @UIBindable var model = CounterModel()

        let document = JSObject.global.document

        var counter = document.createElement("input")
        counter.type = "number"
        _ = document.body.appendChild(counter)
        counter.bind($model.count.toString, to: \.value, event: \.onchange)
            .store(in: &tokens)

        var textField = document.createElement("input")
        textField.type = "text"
        _ = document.body.appendChild(textField)
        textField.bind($model.text, to: \.value, event: \.onkeyup)
            .store(in: &tokens)
        textField.bind(focus: $model.isTextFocused)
            .store(in: &tokens)

        var factButton = document.createElement("button")
        factButton.innerText = "Get fact"
        factButton.onclick = .object(
            JSClosure { _ in
                Task { await model.factButtonTapped() }
                return .undefined
            }
        )
        _ = document.body.appendChild(factButton)

        var factLabel = document.createElement("div")
        _ = document.body.appendChild(factLabel)

        observe {
            if model.factIsLoading {
                factLabel.innerText = "Fact is loading..."
            } else {
                factLabel.innerText = ""
            }
        }
        .store(in: &tokens)

//        alert(item: $model.fact, message: \.value)
//            .store(in: &tokens)

//        alertDialog(item: $model.fact) { _ in
//            "Fact"
//        } message: { fact in
//            fact.value
//        }
//        .store(in: &tokens)

        alertDialog($model.alert)
            .store(in: &tokens)
    }
}

extension Int {
    fileprivate var toString: String {
        get {
            String(self)
        }
        set {
            self = Int(newValue) ?? 0
        }
    }
}
