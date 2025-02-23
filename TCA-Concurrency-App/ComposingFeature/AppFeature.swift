//
//  AppFeature.swift
//  TCA-Concurrency-App
//
//  Created by 鈴木 健太 on 2025/02/23.
//

import ComposableArchitecture
import SwiftUI

struct AppView: View {
  let store1: StoreOf<CounterFeature>
  let store2: StoreOf<CounterFeature>
  
  var body: some View {
    TabView {
      CounterView(store: store1)
        .tabItem {
          Text("Counter 1")
        }
      
      CounterView(store: store2)
        .tabItem {
          Text("Counter 2")
        }
    }
  }
}

import ComposableArchitecture
import SwiftUI

/// `AppFeature` はアプリのメインの Reducer であり、
/// 2つの `CounterFeature` を管理する親の役割を持つ
@Reducer
struct AppFeature {
    
    /// `State` はアプリ全体の状態を表す
    struct State: Equatable {
        /// 1つ目のカウンターの状態（`CounterFeature` の State）
        var tab1 = CounterFeature.State()
        
        /// 2つ目のカウンターの状態（`CounterFeature` の State）
        var tab2 = CounterFeature.State()
    }
    
    /// `Action` はアプリで発生するアクション（イベント）を表す
    enum Action {
        /// 1つ目のカウンターに関連するアクション
        case tab1(CounterFeature.Action)
        
        /// 2つ目のカウンターに関連するアクション
        case tab2(CounterFeature.Action)
    }
    
    /// `body` には `Reducer` の処理を定義する
    var body: some ReducerOf<Self> {
        /// `Scope` を使って `tab1` の状態とアクションを `CounterFeature` に渡す
        Scope(state: \.tab1, action: \.tab1) {
            CounterFeature()
        }
        
        /// `Scope` を使って `tab2` の状態とアクションを `CounterFeature` に渡す
        Scope(state: \.tab2, action: \.tab2) {
            CounterFeature()
        }
        
        /// `Reduce` は `AppFeature` 全体のロジックを処理する
        Reduce { state, action in
            // ここでは特に親としての追加ロジックはない
            // すべての処理は `CounterFeature` に委譲される
            return .none
        }
    }
}
