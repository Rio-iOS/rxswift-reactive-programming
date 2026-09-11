# rxswift-reactive-programming
RxSwift Reactive Programming Fourth Edition

## 検証環境と実行方法

検証用ツールチェーンはXcode 26.6 / Swift 6.3です。Swiftの言語モード・iOSの最低バージョンは各プロジェクトの設定を使用します。macOSでXcodeをインストールし、初回起動時の追加コンポーネントのインストールを完了してください。

リポジトリのルートで以下を実行します。

```sh
# 検証対象と番号の一覧
swift Scripts/verify.swift --list

# 全対象を順番に検証
swift Scripts/verify.swift

# 1件だけ検証（0始まり）
swift Scripts/verify.swift --index 0
```

アプリは署名不要のSimulator向けにビルドし、Swiftパッケージは `swift test` で検証します。作業用ディレクトリは実行ごとに作成・削除するため、初回と同様に時間がかかります。依存パッケージの取得にはネットワーク接続が必要です。

## 検証対象

| 番号 | 対象 | 種類 | 開く場所 |
| ---: | --- | --- | --- |
| 0 | `RxSwiftExample` | Simulatorビルド | `RxSwiftExample/RxSwiftExample.xcodeproj` |
| 1 | `RepositoryActivityCore` | Swift回帰テスト | `./Package.swift` |

アプリを操作するには表のworkspace（ある場合）またはprojectをXcodeで開き、対象のschemeとiPhone Simulatorを選択して実行します。実機で動かす場合は、ご自身のSigning Teamを設定してください。

## CIと検証範囲

`Quality` ワークフローは上記と同じ一覧・スクリプトを使い、対象ごとにビルドまたはテストを実行します。ビルドの成功だけでは、画面表示、アクセシビリティ、通信先の動作、テスト網羅性は保証されません。UIサンプルはSimulator上での操作確認も必要です。

## 振る舞いの回帰テスト

Chapter08は本文・更新日時・対象リポジトリを1つのJSONに原子的に保存し、破損時は条件なしで再取得します。保存失敗は画面へ通知します。Chapter10は指定カテゴリのendpointを使い、空結果とHTTP・デコード失敗を区別します。GeoJSONの経度・緯度とPolygon、nullableなclosedを解釈し、イベントを重複除去して日付順に並べます。

キャッシュの再読み込み・対象の不一致・破損・保存失敗、HTTP 503、カテゴリ別URL、null値、Point／Polygon、イベント順序、購読破棄を検証します。

```sh
swift test
```

EONET教材はAPI v2.1のデータ形式を扱います。v2.1は非推奨です。[NASAのv2.1ドキュメント](https://eonet.gsfc.nasa.gov/docs/v2.1)を参照してください。

## Swiftコード品質

[設計・命名・所有関係の方針と、この教材への適用範囲](SWIFT-QUALITY.md)を参照してください。
