//
//  Effects.swift
//  ComposableArchitecture
//
//  Created by Mizuo Nagayama on 2023/03/12.
//

import Foundation

public func dataTask(with request: URL) -> Effect<(Data?, URLResponse?, Error?)> {
    return Effect { callback in
        URLSession.shared.dataTask(with: request) { data, response, error in
            callback((data, response, error))
        }
        .resume()
    }
}

extension Effect where A == (Data?, URLResponse?, Error?) {
    public func decode<B: Decodable>(as type: B.Type) -> Effect<B?> {
        return self.map { data, _, _ in
            data.flatMap{ try? JSONDecoder().decode(B.self, from: $0) }
        }
    }
}

extension Effect {
  public func receive(on queue: DispatchQueue) -> Effect {
    return Effect { callback in
      self.run { a in
        queue.async { callback(a) }
      }
    }
  }
}
