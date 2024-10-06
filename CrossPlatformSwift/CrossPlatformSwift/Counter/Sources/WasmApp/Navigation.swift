//
//  Navigation.swift
//  Counter
//
//  Created by Mizuo Nagayama on 2024/10/06.
//

import JavaScriptKit
import SwiftNavigation

func alert<Item>(
    item: UIBinding<Item?>,
    message: @escaping @Sendable (Item) -> String
) -> ObserveToken {
    observe {
        if let unwrappedItem = item.wrappedValue {
            _ = JSObject.global.window.alert(message(unwrappedItem))
            item.wrappedValue = nil
        }
    }
}

@MainActor
func alertDialog<Item>(
    item: UIBinding<Item?>,
    title titleFromItem: @escaping @Sendable (Item) -> String,
    message messageFromItem: @escaping @Sendable (Item) -> String
) -> ObserveToken {
    let document = JSObject.global.document

    var dialog = document.createElement("dialog")
    var title = document.createElement("h1")
    title.innerText = "Fact"
    _ = dialog.appendChild(title)
    var message = document.createElement("p")
    _ = dialog.appendChild(message)
    var closeButton = document.createElement("button")
    closeButton.innerText = "Close"
    closeButton.onclick = .object(
        JSClosure { _ in
            item.wrappedValue = nil
            return .undefined
        }
    )
    dialog.onCancel = .object(
        JSClosure { _ in
            item.wrappedValue = nil
            return .undefined
        }
    )
    _ = dialog.appendChild(closeButton)
    _ = document.body.appendChild(dialog)
    _ = dialog.showModal()

    return observe {
        if let unwrappedItem = item.wrappedValue {
            title.innerText = .string(titleFromItem(unwrappedItem))
            message.innerText = .string(messageFromItem(unwrappedItem))
            _ = dialog.showModal()
        } else {
            _ = dialog.close()
        }
    }
}

@MainActor
func alertDialog(
    _ state: UIBinding<AlertState<Never>?>
) -> ObserveToken {
    alertDialog(state) { _ in }
}

@MainActor
func alertDialog<Action: Sendable>(
    _ state: UIBinding<AlertState<Action>?>,
    action handler: @escaping @Sendable (Action) -> Void
) -> ObserveToken {
    let document = JSObject.global.document

    var dialog = document.createElement("dialog")
    var title = document.createElement("h1")
    _ = dialog.appendChild(title)
    var message = document.createElement("p")
    _ = dialog.appendChild(message)

    dialog.onCancel = .object(
        JSClosure { _ in
            state.wrappedValue = nil
            return .undefined
        }
    )
    _ = document.body.appendChild(dialog)

    return observe {
        if let alertState = state.wrappedValue {
            title.innerText = .string(String(state: alertState.title))
            message.innerText = .string(alertState.message.map { String(state: $0) } ?? "")
            message.hidden = .boolean(alertState.message == nil)
            _ = dialog.querySelectorAll("button").forEach(JSClosure { arguments in
                arguments.first!.remove()
            })

            // default button in case state doesn't have any
            if alertState.buttons.isEmpty {
                var closeButton = document.createElement("button")
                closeButton.innerText = "OK"
                closeButton.onclick = .object(
                    JSClosure { _ in
                        state.wrappedValue = nil
                        return .undefined
                    }
                )
                _ = dialog.appendChild(closeButton)
            }
            for buttonState in alertState.buttons {
                var button = document.createElement("button")
                button.innerText = .string(String(state: buttonState.label))
                button.onclick = .object(
                    JSClosure { _ in
                        buttonState.withAction { action in
                            guard let action else { return }
                            handler(action)
                        }
                        state.wrappedValue = nil
                        return .undefined
                    }
                )
                _ = dialog.appendChild(button)
            }
            _ = dialog.showModal()
        } else {
            _ = dialog.close()
        }
    }
}
