//
//  PrimeTimeApp.swift
//  PrimeTime
//
//  Created by Mizuo Nagayama on 2023/02/03.
//

import Counter
import ComposableArchitecture
import SwiftUI

@main
struct PrimeTimeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store<AppState, AppAction>(
                    value: AppState(),
                    reducer: appReducer.activityFeed().logging(),
                    environment: AppEnvironment(
                        nthPrime: nthPrime,
                        offlineNthPrime: offlineNthPrime,
                        fileClient: .live
                    )
                )
            )
        }
    }
}
