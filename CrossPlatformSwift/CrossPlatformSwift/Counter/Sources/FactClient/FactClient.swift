//
//  FactClient.swift
//  Counter
//
//  Created by Mizuo Nagayama on 2024/09/23.
//

import Dependencies
import DependenciesMacros

@DependencyClient
public struct FactClient: Sendable {

    public var fetch: @Sendable (Int) async throws -> String
}

extension FactClient: TestDependencyKey {
    public static let testValue = FactClient()
}
