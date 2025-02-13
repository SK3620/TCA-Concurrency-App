//
//  CounterFeature.swift
//  TCA-Concurrency-App
//
//  Created by 鈴木 健太 on 2025/02/10.
//

import ComposableArchitecture
import Foundation

// @Reducer マクロを使って、TCA（The Composable Architecture）のReducerを定義
// Reducerとは「今の状態 (State)」と「実行された操作 (Action)」を受け取って、状態を変更する処理を書く場所」 のこと
@Reducer
struct CounterFeature {
    
    // @ObservableState を使うと、ViewがこのStateを監視できる 状態の変化に反応して自動的に再描画を行う
    // iOS 17 未満のアプリでは、View 全体 を WithPerceptionTracking で囲む必要がある
    @ObservableState
    struct State {
        var count = 0  // カウンターの現在の値（初期値は0）
        var fact: String?
        var isLoading = false
        var isTimerRunning = false
    }
    
    // ユーザーが実行できるアクション（ボタンのタップ）
    enum Action {
        case decrementButtonTapped  // 「-」ボタンをタップ
        case incrementButtonTapped  // 「+」ボタンをタップ
        case factButtonTapped
        case factResponse(String)
        case timerTick
        case toggleTimerButtonTapped
    }
    
    enum CancelID { case timer }
    
    // some ReducerOf<Self> を使うことで、「この Reducer は CounterFeature のものですよ」 ということを明示
    // 「アクションが来たら、どう State を変更するか？」を決める処理をまとめる場所
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // state: 現在の状態 (CounterFeature.State)
            // action: ユーザーが実行した操作 (CounterFeature.Action)
            switch action {
            case .decrementButtonTapped:
                state.count -= 1  // `-` ボタンを押したらカウントを減らす
                state.fact = nil
                return .none  // Effect を返さない（副作用なし）
                
            case .factButtonTapped:
                state.fact = nil
                state.isLoading = true
                
                // ---------------------------
                /*
                 ・Reducer 内で await を使うことはできない
                 ・エラーハンドリングが行われていない
                 そこで非同期リクエストを実行するにはEffectを活用！
                 
                 let (data, _) = try await URLSession.shared
                 .data(from: URL(string: "http://numbersapi.com/\(state.count)")!)
                 state.fact = String(decoding: data, as: UTF8.self)
                 */
                // ---------------------------
                
                // ---------------------------
                /*
                 Effect.run(operation: (Send<Action>) -> Void)
                 public static func run(
                 operation: @escaping @Sendable (_ send: Send<Action>) async throws -> Void...)
                 */
                // ---------------------------
                return .run { [count = state.count] send in
                    // numbersapi.com というAPIから数値の情報を取得
                    let (data, _) = try await URLSession.shared
                        .data(from: URL(string: "http://numbersapi.com/\(count)")!)
                    let fact = String(decoding: data, as: UTF8.self)
                    // しかし、Effect.run {} のクロージャは Sendable でなければならず、state を直接変更することはできません。
                    // そのため、非同期処理の結果を factResponse アクションとして送信し、Reducer で処理します。
                    await send(.factResponse(fact))
                }
                
            case let .factResponse(fact):
                // factResponse アクションが Reducer で処理され、状態を更新
                state.fact = fact
                state.isLoading = false
                return .none
                
                
            case .incrementButtonTapped:
                state.count += 1  // `+` ボタンを押したらカウントを増やす
                state.fact = nil
                return .none  // Effect を返さない（副作用なし）
                
            case .timerTick:
                state.count += 1
                state.fact = nil
                return .none
                
            case .toggleTimerButtonTapped:
                state.isTimerRunning.toggle()
                if state.isTimerRunning {
                    return .run { send in
                        while true {
                            try await Task.sleep(for: .seconds(1))
                            await send(.timerTick)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                } else {
                    return .cancel(id: CancelID.timer)
                }
            }
        }
    }
}

/*
〜 Effect 〜
 Step 1: Effect の基本
 TCA において Effect は、非同期処理を実行するための仕組みです。
 Reducer は純粋な状態の変換を担当し、Effect は外部システムとやり取りするために使われます。
 Effect は Store によって実行され、外部データを取得してから Reducer にデータを戻す役割を持つ。

 Step 2: Effect を使った非同期処理の記述方法
 TCA では、Effect を作成するためのメソッド .run {} を提供しています。
 この .run のクロージャ内で非同期処理を行い、結果を send を使って Reducer に返します。
*/

/*
〜 Reducer内でawaitは使用不可 〜
 Reducer は 同期処理 しか許可されていません。そのため、以下のような await を直接書くコードはエラーになります。
 let (data, _) = try await URLSession.shared
     .data(from: URL(string: "http://numbersapi.com/\(state.count)")!)
 これは TCA が「純粋関数」の考え方を採用しているため です。
 Reducer では単純な状態の変換のみを行い、非同期処理のような「副作用」は Effect に分離する設計になっています。
*/
