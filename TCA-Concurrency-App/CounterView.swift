//
//  CounterView.swift
//  TCA-Concurrency-App
//
//  Created by 鈴木 健太 on 2025/02/11.
//

import SwiftUI
import ComposableArchitecture

struct CounterView: View {
    // Store: 状態の保存、変更、アクションの発行を担当
    // 状態 (State) とアクション (Action) の管理 を担うオブジェクト
    let store: StoreOf<CounterFeature>
    // typealias StoreOf<R> = Store<R.State, R.Action> where R : Reducer
    // R.State はその Reducer に関連する状態（例えば CounterFeature.State）。
    // R.Action はその Reducer に関連するアクション（例えば CounterFeature.Action）。
    
    
    var body: some View {
        VStack {
            Text("\(store.count)")
                .font(.largeTitle)
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
            HStack {
                Button("-") {
                    store.send(.decrementButtonTapped)
                }
                .font(.largeTitle)
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
                
                Button("+") {
                    store.send(.incrementButtonTapped)
                }
                .font(.largeTitle)
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
                
                Button("Fact") {
                    store.send(.factButtonTapped)
                }
                .font(.largeTitle)
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
                
                if store.isLoading {
                    ProgressView()
                } else if let fact = store.fact {
                    Text(fact)
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
    }
}

#Preview {
    CounterView(store: Store(initialState: CounterFeature.State(), reducer: { CounterFeature() }))
    // CounterView の初期化 CounterFeature.State() は、State 構造体の初期値（この場合、count = 0）を作成
    // CounterView は、Store を受け取るビューです。store プロパティを使って、ビューが状態を表示したりアクションを送信したりできるようになります。
    
    // reducer: { CounterFeature() }
    // reducer クロージャには、CounterFeature() を返すコードが書かれています。CounterFeature は Reducer です。この部分で、状態の変更方法（アクションを受けて状態を更新するロジック）を提供
}
