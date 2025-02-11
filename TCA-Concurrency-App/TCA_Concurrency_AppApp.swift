//
//  TCA_Concurrency_AppApp.swift
//  TCA-Concurrency-App
//
//  Created by 鈴木 健太 on 2025/01/20.
//

import ComposableArchitecture
import SwiftUI

@main
struct MyApp: App {
  static let store = Store(initialState: CounterFeature.State()) {
    CounterFeature()
      ._printChanges()
      // printChanges: Reducer が処理するすべてのアクションがコンソールに出力され、アクションの処理後に状態がどのように変化したかが出力されます
  }
  
  var body: some Scene {
    WindowGroup {
      CounterView(store: MyApp.store)
    }
  }
}
