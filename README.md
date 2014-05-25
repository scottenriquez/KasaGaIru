傘が要る？
==========

「傘が要る？」iOS天気予報アプリケーションの概要と特徴について

概要：
＊使った外部リソースの情報にのリンクを一番下に張ります＊

iOS向けの天気予報アプリケーション。表示される情報が無料で使える天気予報情報
を提供しているOpenWeatherというAPIの使用によって取得して表示しています。

使用したOpen Sourceライブラリ：
CocoaPodsにより、以下のOpen Source iOSライブラリを活用しました。

1. LBBlurredImage - UIImageのCategoryでこのアプリのメイン画面の背景UIImage
   を簡単にブラー効果を適用できました。

2. Mantle - これを使ってOpenWeatherのAPIから取得していたJSONオブジェクトの
   iOSネイティブオブジェクトにのマッピングをしました。

3. ReactiveCocoa - このライブラリを使う有利はUIを直接Modelの情報に紐づける
   ことができることです。あるUIViewのUIViewControllerにRACObserverのマクロ
   で、Modelの情報更新について通知されることが可能です。この仕組みを設置したら、
   Modelの情報が変わったら、自動的にUIのエレメントと同期されるようにすることが
   できます。


特徴：
このアプリの機能を設計段階で洗い出していた時に、そもそも天気予報を使う理由について
考えてみました。自分にとっての使う理由が「出かける前に持っていくまたは着るべき物を
決めるため」だと思いました。

その後、人の普通の「出かける」目的について考えてみるとパターンの二つがあるかと
思いました：

　1. 仕事、学校等の為、一日中に家にいなくて、帰るのが夜の遅くなるパターン。
　2. 近くのスーパで買い物、クリーニングから服の取り出し等の為、一二時間以内に
　　　帰ってくるパターン。

＊確かに、この二つのパターンだけではないと思うけど、いずれかの一つである場合が
殆どかと思います＊

この思考により以下の機能を天気予報の普通の情報収集機能の上の実装しました。

　1. ユーザがアプリの設定画面にて日傘が要る最低温度とジャケットが要る最高温度を
　　　閾値として指摘することをできるようにしました。
　2. 1.の設定により、ジャケットと日傘が必要なのかを絵のインディケーターで表示しています。
　　　それかつ、普通の傘が要るかどうかを天気情報分析により表示しています。これはただ、
　　　水分のある天気があれば傘が要るという論理でインディケータの表示・非表示が決まる
　　　ことになっています。「日傘と普通の傘は同じインディケーターを使っています」  
　3. これに加えて、以上の「出かけるの二つのパターン」に合わせる様に、現在に必要なアイテム
　　　を上の方に指摘していて、今日が終わるまで（23:59)に必要なアイテムを下のToday's 
　　　Inventoryの所に表示しています。

追加開発すれば実装したいこと：

　1. アプリを開ける必要ないようになるため、iOSのLocalまたはPush Notifications
     によりユーザが設定してくれる「平日に出かける時間帯」の少し前に、指定した「出かけ先」
     を活用して「今日に必要なアイテム」をできるだけ正確的に予想して送信する機能。
  2. ユーザのカレンダーとの連携、または「出かける詳細画面」で指定してくれる行き場と
     出かける時間帯を使って取得する天気情報で必要なものをユーザに伝えてあげる機能。
  3. カレンダー連携によって、ユーザが予定している外出がある日に嵐などがくるようで
  　　あれば予めにPush Notificationなどで「リスケをする？」という警戒メッセージ
  　　を送信する機能。
  4. 複数の位置追加により、複数の位置の天気予報が見える機能。
  5. 子育てしている人の為、又は主人が要る人の為、複数の「平日に出かける時間帯」と
     「出かけ先」を人数で入れることができる機能によって、家族の人が必要な物が見える機能。
  6. 他言語対応。
  
  などなど 

改善点：

　1. 他の天気情報APIにより、一時間毎に天気情報の表示。
　2. 計り単位の変更により天気情報の再取得をやめること。
　3. データを最初に取得している時に、UIActivityIndicatorか何かによって、処理中である
　　　ことをユーザに見せること。

  などなど

外部リソースの情報：

Open Weather API: http://openweathermap.org/API
CocoaPods: http://cocoapods.org/
ReactiveCocoa: https://github.com/ReactiveCocoa/ReactiveCocoa
Mantle: https://github.com/Mantle/Mantle
LBBlurredImage: https://github.com/lukabernardi/LBBlurredImage
天気の画像: http://www.raywenderlich.com/55384/ios-7-best-practices-part-1
＊アプリのアイコン、Umbrellaとジャケットリソースを自分で描きました。＊
