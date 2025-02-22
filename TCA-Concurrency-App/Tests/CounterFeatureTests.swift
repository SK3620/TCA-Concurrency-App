//
//  CounterFeatureTests.swift
//  TCA-Concurrency-App
//
//  Created by 鈴木 健太 on 2025/02/17.
//

import ComposableArchitecture
import Testing

@testable import Pods_TCA_Concurrency_App

// TCAを使って、カウンター機能（ボタンを押すと数値が増減する機能） のテスト
@MainActor
struct CounterFeatureTests {
    @Test
    func basics() async {
        // テストのコードはここに書く
        
        // TCA では TestStore を使って、アクション（ボタンを押すなどの操作）が状態をどのように変化させるかをテスト
        
        // テスト用のストアを作成
        // ① 初期状態 (initialState) を設定
        // ② 実際の機能 (CounterFeature()) を渡し
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }
        
        // テストでは「現在の状態」と「期待する状態」を比較するために、
        // State が Equatable に適合している必要があります。
        //（TCA の State は基本的に Equatable に適合するように設計されています。）
        
        // ここで、{ $0.count = 1 } のように書くことで
        //「アクション後に状態がどうなるべきか」を明示します。
        //（状態が想定と異なるとテストが失敗します）
        await store.send(.incrementButtonTapped) {
            $0.count = 1
          }
        await store.send(.decrementButtonTapped) {
            $0.count = 0
        }
        
        /*
        await store.send(.incrementButtonTapped)
        // ❌ State was not expected to change, but a change occurred: …
        //
        //       CounterFeature.State(
        //     −   count: 0,
        //     +   count: 1,
        //         fact: nil,
        //         isLoading: false,
        //         isTimerRunning: false
        //       )
        //
        // (Expected: −, Actual: +)
        await store.send(.decrementButtonTapped)
        // ❌ State was not expected to change, but a change occurred: …
        //
        //       CounterFeature.State(
        //     −   count: 1,
        //     +   count: 0,
        //         fact: nil,
        //         isLoading: false,
        //         isTimerRunning: false
        //       )
        //
        // (Expected: −, Actual: +)
         */
    }
}
