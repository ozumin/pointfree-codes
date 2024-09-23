//
//  FactClientLive.swift
//  Counter
//
//  Created by Mizuo Nagayama on 2024/09/23.
//

import FactClient
import Dependencies
import DependenciesMacros
#if canImport(JavaScriptKit)
@preconcurrency import JavaScriptKit
#endif
#if canImport(JavaScriptEventLoop)
import JavaScriptEventLoop
#endif

extension FactClient: DependencyKey {
    public static let liveValue = FactClient { number in
        #if canImport(JavaScriptKit) && canImport(JavaScriptEventLoop)
        let response = try await JSPromise(
            JSObject.global.fetch!("http://www.numberapi.com/\(number)").object!
        )!.value

        let fact = try await JSPromise(response.text().object!)!.value.string!
        return fact
        #else
        let loadedFact = try await String(
            decoding: URLSession.shared
                .data(
                    from: URL(string: "http://www.numberapi.com/\(number)")!
                ).0,
            as: UTF8.self
        )
        return loadedFact
        #endif
    }
}
