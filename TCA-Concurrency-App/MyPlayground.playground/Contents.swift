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
