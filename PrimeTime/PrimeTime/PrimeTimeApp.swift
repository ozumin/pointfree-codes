//
//  PrimeTimeApp.swift
//  PrimeTime
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import ComposableArchitecture
import SwiftUI

@main
struct PrimeTimeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store<AppState, AppAction>(
                    value: AppState(),
                    reducer: logging(activityFeed(appReducer))
                )
            )
        }
    }
}
