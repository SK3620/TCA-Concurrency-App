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

// Task → TaskはSwift Concurrencyにおいて非同期処理を実行する基本単位である。同期メソッド内で非同期処理を実行する必要があるときに使用し、非同期関数を呼び出すための文脈を作るために使う。
// Task.init(operation: { () async -> Void in })
// 呼び出し
Task {
    do {
        let hello1 = try await hello()  // `hello()` を実行（待機）
        let world1 = try await world()  // helloの完了後、`world()` を実行（待機）
        print(hello1 + world1)          // `hello1` と `world1` を出力
        
        async let hello2 = hello()  // 並行に hello() を実行
        async let world2 = world()  // 並行に world() を実行
        // hello()とworld()どちらの完了を待ってからprint出力
        try await print(hello2 + world2) // `hello2` `world2` の結果を取得し出力
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
            // result → コールバックの結果
            // continuation.resume(returning: result
            continuation.resume(returning: result)
            // ここで async 関数の戻り値として返す
        }
    }
}

// ④ async/await を使って呼び出す
Task {
    // continuation を再開（resume）することで、非同期関数の戻り値（String型）を設定します。
    // これによって asyncHello() は await を抜けて result を返すことができます
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

// MARK: - エラーが発生するコールバック関数を非同期関数に変換
struct MyError: Error {}
// エラーが発生するコールバック関数
func hello(completion: (Result<String, Error>) -> ()) {
    sleep(3) // 時間のかかる処理
    let hasError = Bool.random()
    if hasError {
        completion(.failure(MyError()))
    } else {
        completion(.success("Hello"))
    }
}

// 非同期関数に変換
func asyncHello() async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
        // コールバックの結果を continuation.resume(returning:) で返す
        hello { result in
            continuation.resume(with: result)
        }
    }
}

// init(priority: TaskPriority?, operation: () async -> Success)
// Task.init(operation: { () async -> Void in })
// クロージャにはasyncがついているのでTaskのスコープの中ではawaitができる
// Taskなしでは、同期的な処理になるため、コンパイルエラーになる
Task {
    do {
        let hello = try await asyncHello()
        print(hello)
    } catch {
        print("Error")
    }
}

// MARK: - Task.init
override func viewDidLoad() {
  super.viewDidLoad()
  
  // ⭐️ここはメインスレッド
  Task {
    // このTaskを実行するスレッドはTask初期化の呼び出し元のコンテキストを引き継ぎます。
    // つまり、このTask内の同期処理はメインスレッドで実行されます。

    // 非同期関数`fetchTodo(id:)`はバックグランドスレッドで処理されます。
    // その間このTask内の処理は一時停止し、メインスレッドを明け渡します。
    // メインスレッドはブロックされず、他の処理（例えば UI の更新やユーザー入力の処理など）が続行できる。

    let todo = try! await fetchTodo(id: 1)
    
    // `fetchTodo(id:)`メソッドが完了するとこのTaskが再開します。
    // このTask内の同期処理はメインスレッドで実行されるので、ここもメインスレッドです。
    view.addSubview(TodoView(todo)) // 👌
  }
}

// DispatchQueue.global().async との違い
DispatchQueue.global().async {
    let todo = fetchTodoSync(id: 1)  // 完全同期処理（await なし）
    DispatchQueue.main.async {
        view.addSubview(TodoView(todo))
    }
}
/*
 DispatchQueue.global().async
 を使うと、最初からバックグラウンドスレッドで動くが、完了後にDispatchQueue.main.async で明示的にメインスレッドに戻る必要がある。
 Taskはコンテキストを引き継ぐので、最初のスレッドがメインなら、完了後もメインスレッドに戻る！
 非同期処理中もメインスレッドが解放される点は共通だが、Swift Concurrencyの方が簡潔で安全。
*/

// MARK: - データ競合
// マルチスレッドプログラミングにおいて、重要な問題はデータ競合（data race)をいかに防ぐかです。複数のスレッドから一つのデータにアクセスした場合、あるスレッドがデータを更新するとデータが不整合を起こしてしまう可能性があります。デバックが非常に難しくやっかいなバグをになることが多いです。
// 以下はデータ競合の例
class Score {
    var logs: [Int] = []
    private(set) var highScore: Int = 0

    func update(with score: Int) {
        logs.append(score)
        if score > highScore { // ①
            highScore = score // ②
        }
    }
}
//updateメソッドでは渡されたスコアをlogsに追加し、最高得点よりも多かったらそのスコアでhighScoreプロパティを更新するというシンプルな処理になっています。
//複数スレッドからupdateメソッドを実行して何が起こるかをみてみます。

let score = Score()
DispatchQueue.global(qos: .default).async {
    score.update(with: 100) // ③
    print(score.highScore)  // ④
}
DispatchQueue.global(qos: .default).async {
    score.update(with: 110) // ⑤
    print(score.highScore)　// ⑥
}
//期待する出力は順不同で100, 110が出力されることです。
//③と④はそれぞれ別スレッドで同じscoreインスタンスに対してメソッドを実行します。
//データ競合がなければ、それぞれ渡した点数がhighScoreとして出力されるはずです。
//
//ところが、Swift Playgroundで何回か実行すると、どちらも100になる場合や、110になる場合があります。
//
//これはupdateメソッド中で、①scoreが最高点数かを判断する行から②highScoreを更新する行に処理が渡る間にデータの不整合が起こるからです。
//
//例えば、以下の順番で処理が進むとどちらの出力も100になります。
//
//③が①を通過
//⑤が①と②を通過し、highScoreが110になる
//③が②を通過し、highScoreが100になる
//④が通過し、100を出力
//⑥が通過し、100を出力

// MARK: - Actor データ競合解決
// actorとは？
// 新しい型の種類
// 参照型
// インスタンスに外からアクセスするものは、同時に一つのみに限定される（2つ以上の場所（スレッド）から同時にアクセスすることはできない） → Actor隔離 Actor isolatedと呼ぶ
// 並行処理でデータ競合を防ぐための仕組み
// 外からアクセスする際はawaitが必要
// イニシャライザー、プロパティ、メソッド定義、プロトコル適応などclass, struct, enumを同じ特徴をもつ
actor Score2 {
    var logs: [Int] = []
    private(set) var highScore: Int = 0

    func update(with score: Int) {
        logs.append(score)
        if score > highScore { // ①
            highScore = score // ②
        }
    }
}
let score2 = Score2()
Task.detached(operation: { () -> Void in
    await score2.update(with: 100)
    print(await score2.highScore) // awaitをつけるルール
})
Task.detached(operation: { () -> Void in
    await score2.update(with: 110)
    print(await score2.highScore)
})
// どちらも100になる場合や、110になる場合がなくなり
// 必ず、100, 110が順不同で出力される（データ競合がなくなる）

// MARK: - actorで競合状態（Race Condition）防げない

// 競合状態(Race Condition) マルチスレッドにおける典型的な不具合一つ
// プログラミング実行結果が各スレッド実行順に依存する状態
// 同じ入力を与えても異なるデータを出力する状態

// actorには 再入可能性（Reentrancy） があるため、場合によっては 競合状態（Race Condition） が発生する可能性がある

import Foundation

actor Counter {
    private var value = 0

    func increment() async -> Int {
        let current = value  // `value` を取得
        await Task.sleep(1_000_000_000)  // 1秒待機（他のタスクが割り込める）こいつが悪い。
        value = current + 1  // `value` を更新
        return value
    }
}

@main
struct Main {
    static func main() async {
        let counter = Counter()

        // 2つの非同期タスクを並行実行
        async let task1 = counter.increment()
        async let task2 = counter.increment()

        let result1 = await task1
        let result2 = await task2

        print("Result 1: \(result1), Result 2: \(result2)")
    }
}
/*
 このコードでの競合の流れ
 task1 が counter.increment() を呼び出し、value を取得（例えば 0）。
 task1 が await Task.sleep(...) に到達し、一時的に中断。
 task2 も counter.increment() を呼び出し、value を取得（0）。
 task2 も await Task.sleep(...) に到達し、一時的に中断。
 task1 が再開し、value = 0 + 1 に更新（value = 1）。
 task2 も再開し、同じ値 0 に +1 をして value = 1 に更新（本来 2 になるべき）。
 期待する結果は 1 と 2 だが、実際には 1 と 1 になる可能性がある（データ競合が発生）。
*/

// データの変更を一貫して直列化するために nonisolated な await を避け、Task.sleep を別スレッドで実行しないようにする方法がある。
actor Counter {
    private var value = 0

    func increment() async -> Int {
        value += 1  // `await` せずに直列実行
        return value
    }
}
// このようにすると value の変更が中断されず、競合状態が発生しない。

// MARK: - actorで競合状態（Race Condition）防げない②
//一方で、再入可能性によりawaitの前後で状態が変わる可能性があります。（= 競合状態（race condition））
//例えば以下のコードではcountの値は最初は0ですが、await後は1になります。

actor Demo {
    var count = 0

    func doWork() async {
        print("📝 before sleep count: \(count)")

        // awaitにより他のタスクがここまで到達する可能性がある
        try! await Task.sleep(nanoseconds: 5_000_000_000)

        // countの値がawaitの前後で一致しない可能性がある
        print("📝 after sleep count: \(count)")
    }

    func increment() {
        count += 1
    }
}

let demo = Demo()

Task {
    await demo.doWork()
}

Task {
    await demo.increment()
}

// （出力）
//📝 before sleep count: 0
//📝 after sleep count: 1

//この問題への対応としては以下の対応が可能です。
//
//状態変更を同期的に（awaitを挟まずに）実行する
//await後に再度状態を確認する

