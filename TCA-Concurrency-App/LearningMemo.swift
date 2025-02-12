//
//  LearningMemo.swift
//  TCA-Concurrency-App
//
//  Created by 鈴木 健太 on 2025/02/12.
//

/*
 1. なぜ Reducer は同期処理しか実行できないのか？
 TCA（The Composable Architecture）において、Reducer は 「純粋関数（pure function）」 であることが求められています。
 純粋関数とは、次のような特性を持つ関数のことです。

 同じ入力 に対して 常に同じ出力 を返す
 副作用（Side Effect） を持たない（例：ネットワーク通信、ファイル書き込み、タイマー処理など）
 例えば、以下のような関数は 純粋関数 です。

 func add(_ a: Int, _ b: Int) -> Int {
     return a + b  // 何度呼び出しても同じ結果が返る
 }
 一方、以下のような関数は 非純粋関数（impure function） です。

 var counter = 0

 func increment() -> Int {
     counter += 1  // 関数の外部状態を変更している（副作用）
     return counter
 }
 Reducer を 純粋関数にすることで、アプリの状態管理がシンプルになり、バグを減らすことができる というのが、TCA の基本的な設計思想です。

 しかし、ネットワークリクエストのような 非同期処理 は、副作用を伴うため 純粋関数ではない という問題があります。
 そこで、TCA では Effect を使って、副作用を Reducer の外部に追い出すことで、純粋関数の性質を守りつつ非同期処理を扱えるようにしています。

 2. なぜ同期処理しか実行できないと、非同期処理ができないのか？
 Reducer は「純粋関数」であり、「副作用」を持たないように設計されているため、非同期処理を直接実行することができません。
 非同期処理は、以下のように 時間がかかる処理 であるため、関数がすぐに結果を返せない性質があります。

 swift
 コピーする
 編集する
 func fetchData() async -> String {
     let (data, _) = try await URLSession.shared.data(from: URL(string: "http://numbersapi.com/42")!)
     return String(decoding: data, as: UTF8.self)
 }
 例えば、以下のように Reducer 内で非同期処理をしようとすると、エラーになります。

 swift
 コピーする
 編集する
 Reduce { state, action in
     switch action {
     case .factButtonTapped:
         let (data, _) = try await URLSession.shared.data(from: URL(string: "http://numbersapi.com/42")!)
         state.fact = String(decoding: data, as: UTF8.self)  // ❌ エラー！
         return .none
     }
 }
 エラーの理由：

 Reducer は 同期関数 である（すぐに結果を返す必要がある）
 しかし await は非同期処理のため、すぐに結果を返せない
 そのため Reducer の中で await を使うことが許されていない
 つまり、「同期関数しか使えない場所で非同期処理を行おうとすると、関数がすぐに結果を返せないためエラーになる」ということです。

 3. Effect.run {} を使う理由
 TCA では Effect.run {} を使うことで、非同期処理を Reducer の外部に切り出し、副作用を適切に管理することができます。

 swift
 コピーする
 編集する
 case .factButtonTapped:
     state.fact = nil
     state.isLoading = true
     return .run { [count = state.count] send in
         let (data, _) = try await URLSession.shared
             .data(from: URL(string: "http://numbersapi.com/\(count)")!)
         let fact = String(decoding: data, as: UTF8.self)
         await send(.factResponse(fact))
     }
 この方法を使うことで、次のような流れで 非同期処理を Reducer から分離 できます。

 .factButtonTapped のアクションが発火（Reducer の処理）
 Effect.run {} が実行され、非同期処理を開始
 ネットワークリクエストが完了すると、send(.factResponse(fact)) で結果を Reducer に送信
 Reducer で .factResponse(fact) を受け取り、state を更新
 このように Effect.run {} を使うことで、

 Reducer の 純粋性を保ちながら
 Effect によって 非同期処理を安全に実行できる という設計になっています。
 4. Sendable とは？
 Sendable とは、「スレッド間で安全にやり取りできるデータの型」を表す Swift のプロトコル です。

 TCA では、Effect.run {} のクロージャの中で state にアクセスすると、以下のようなエラーが発生します。

 swift
 コピーする
 編集する
 return .run { send in
     let count = state.count  // ❌ コンパイルエラー！
 }
 なぜエラーになるのかというと、

 Effect.run {} のクロージャは 並行処理（Concurrency） の中で実行される
 Reducer の state は、スレッドセーフではない（並行処理で直接アクセスできない）
 Swift では スレッドセーフでないデータを別のスレッドで扱うことは禁止されている
 つまり、state は Sendable ではないため、Effect.run {} のクロージャの中で state を直接参照することができない のです。

 解決策: [count = state.count] で値をコピー
 swift
 コピーする
 編集する
 return .run { [count = state.count] send in
     let (data, _) = try await URLSession.shared
         .data(from: URL(string: "http://numbersapi.com/\(count)")!)
     let fact = String(decoding: data, as: UTF8.self)
     await send(.factResponse(fact))
 }
 [count = state.count] とすることで、state.count の値をクロージャの外でコピー
 count は Int 型なので Sendable （スレッド間で安全に使える）
 これにより、Effect.run {} のクロージャの中で count を安全に使用できる
 このように、Sendable ではないデータ（state）を直接扱うのではなく、必要な値だけコピーして渡す ことで、安全に非同期処理を実行できます。

 まとめ
 Reducer は同期処理しか実行できない

 非同期処理を実行すると、関数がすぐに結果を返せないためエラーになる
 そのため、非同期処理は Effect.run {} を使って Reducer の外部に分離する
 Effect.run {} を使うと、副作用を Reducer から分離できる

 Effect 内で非同期処理を実行し、結果を send(.factResponse(fact)) で Reducer に返す
 これにより、Reducer の純粋性を保ちながら非同期処理が可能になる
 Sendable とは、スレッド間で安全にやり取りできるデータ

 Effect.run {} のクロージャ内では state に直接アクセスできない
 [count = state.count] のように、値をコピーして渡すことで Sendable の制約を回避できる
 この設計によって、TCA では 状態管理がシンプルになり、バグを減らしつつ安全な非同期処理ができる ようになっています。
 */
