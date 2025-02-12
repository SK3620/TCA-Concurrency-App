//
//  CounterFeature.swift
//  TCA-Concurrency-App
//
//  Created by 鈴木 健太 on 2025/02/10.
//

import ComposableArchitecture

// @Reducer マクロを使って、TCA（The Composable Architecture）のReducerを定義
// Reducerとは「今の状態 (State)」と「実行された操作 (Action)」を受け取って、状態を変更する処理を書く場所」 のこと
@Reducer
struct CounterFeature {
    
    // @ObservableState を使うと、ViewがこのStateを監視できる 状態の変化に反応して自動的に再描画を行う
    // iOS 17 未満のアプリでは、View 全体 を WithPerceptionTracking で囲む必要がある
    @ObservableState
    struct State {
        var count = 0  // カウンターの現在の値（初期値は0）
    }
    
    // ユーザーが実行できるアクション（ボタンのタップ）
    enum Action {
        case decrementButtonTapped  // 「-」ボタンをタップ
        case incrementButtonTapped  // 「+」ボタンをタップ
    }
    
    // some ReducerOf<Self> を使うことで、「この Reducer は CounterFeature のものですよ」 ということを明示
    // 「アクションが来たら、どう State を変更するか？」を決める処理をまとめる場所
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // state: 現在の状態 (CounterFeature.State)
            // action: ユーザーが実行した操作 (CounterFeature.Action)
            switch action {
            case .decrementButtonTapped:
                state.count -= 1  // `-` ボタンを押したらカウントを減らす
                return .none  // Effect を返さない（副作用なし）
                
            case .incrementButtonTapped:
                state.count += 1  // `+` ボタンを押したらカウントを増やす
                return .none  // Effect を返さない（副作用なし）
            }
        }
    }
}

