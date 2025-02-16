import UIKit
import Foundation

var greeting = "Hello, playground"

// エラーが発生する場合
func hello() async throws -> String {
    try await Task.sleep(until: .now + .seconds(3)) // 時間のかかる処理
    return "Hello"
}

func world() async throws -> String {
    try await Task.sleep(until: .now + .seconds(3)) // 時間のかかる処理
    return "World"
}

// Task.init(operation: { () async -> Void in })
// 呼び出し
Task {
    do {
        let hello1 = try await hello()
        let world1 = try await world()
        print(hello1 + world1)
        
        async let hello2 = hello()
        async let world2 = world()
        try await print(hello2 + world2)
    } catch {
        print("error")
    }
}

// MARK: - コールバック関数を非同期関数へ変換
// withCheckedContinuationを使うことで既存のコールバック関数を非同期関数へ変換することができます
// エラーが発生するコールバック関数の場合は、withCheckedThrowingContinuationを使用します

// ① これは従来の「コールバック関数」を使った非同期処理
func hello(completion: (String) -> Void) {
    sleep(3) // 3秒かかる処理（例えばAPI通信など）
    completion("Hello") // 処理が終わったら "Hello" を返す
}

// ② コールバック関数を使って呼び出す場合
hello { result in
    print(result) // "Hello" が表示される（でも 3 秒待たないとダメ）
}

// コールバックの問題点:
// - 非同期処理の完了を待つのが難しい
// - コードのネストが深くなりがち
// - 他の非同期処理と組み合わせるのが面倒


// ③ withCheckedContinuation を使って「hello」を async 関数に変換
func asyncHello() async -> String {
    return await withCheckedContinuation { continuation in
        // コールバックの結果を continuation.resume(returning:) で返す
        hello { result in
            continuation.resume(returning: result) // ここで async 関数の戻り値として返す
        }
    }
}

// ④ async/await を使って呼び出す
Task {
    let result = await asyncHello()
    print(result) // "Hello"（3秒待ってから表示される）
}

// 1. withCheckedContinuation のクロージャ内で、従来のコールバックを呼び出す
// 2. そのコールバックの結果を continuation.resume(returning:) で返す
// 3. すると、async 関数の戻り値として結果を取得できる
// 4. await を使って簡単に非同期処理を待てるようになる

// ✅ コードのネストがなくなってスッキリ
// ✅ async/await なので、他の非同期処理と組み合わせやすい
// ✅ 直感的に処理の流れがわかりやすくなる

// 🚨 continuation.resume(returning:) は「1回だけ」呼ぶこと！
//    2回以上呼ぶとクラッシュするので注意！（Swift は1回しか結果を返せないルール）
