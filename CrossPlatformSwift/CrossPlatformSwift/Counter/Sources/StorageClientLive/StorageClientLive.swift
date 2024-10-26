//
//  StorageClientLive.swift
//  Counter
//
//  Created by Mizuo Nagayama on 2024/10/26.
//

import Foundation
import Dependencies
import StorageClient

#if os(WASI)
import JavaScriptKit
#endif

extension StorageClient: DependencyKey {
  #if os(WASI)
  public static let liveValue = Self(
    load: { key in
      guard let value = JSObject.global.window.localStorage.getItem(key).string else {
        struct DataLoadingError: Error {}
        throw DataLoadingError()
      }
      return Data(value.utf8)
    }, save: { data, key in
      JSObject.global.window.localStorage.setItem(
        key,
        String(decoding: data, as: UTF8.self)
      )
    }
  )
  #else
  public static let liveValue = Self(
    load: { key in
      let url = URL.documentsDirectory.appendingPathExtension(key).appendingPathExtension("json")
      return try Data(contentsOf: url)
    }, save: { data, key in
      let url = URL.documentsDirectory.appendingPathExtension(key).appendingPathExtension("json")
      try data.write(to: url)
    }
  )
  #endif
}
