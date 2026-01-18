# Rytmica

**BPMや音符関連の計算をするアプリ**

このアプリは、音ゲーや音楽制作、演奏時に便利なBPM（テンポ）や音符の長さに関する計算を行うツールです。

## ダウンロード

### App Store (macOS / iOS / iPadOS)
[![Download on the App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/jp/app/rytmica/id6757244924)

macOS版とiOS/iPadOS版がApp Storeで公開されています。

### Microsoft Store (Windows)
<a href="https://apps.microsoft.com/detail/9n7hmk8tn36x?mode=direct">
	<img src="assets/microsoft-store-badge.png" width="200"/>
</a>

Windows版がMicrosoft Storeで公開されています。

### Linux / Android
Linux版とAndroid版は[GitHubの最新リリース](https://github.com/ryuya0124/rytmica/releases/latest)からダウンロードできます。

## アプリ画面例
| 音符計算画面 | 音符回数画面 |
| --- | --- |
| ![音符計算画面](https://github.com/user-attachments/assets/31724174-d531-4497-8d14-f493c64bb9df) | ![音符回数画面](https://github.com/user-attachments/assets/bf9d286c-aad7-42a8-bdc7-503c28cd42c7) |

| 音符換算画面 | 音符換算画面(展開) |
| --- | --- |
| ![音符換算画面](https://github.com/user-attachments/assets/00194d00-36c2-4aef-8ad1-fdb914e04daa) | ![音符換算画面(展開)](https://github.com/user-attachments/assets/a9e40091-57e7-4af1-b459-abeb61ddb7f1) |

| メトロノーム画面 |  |
| --- | --- |
| ![メトロノーム画面](https://github.com/user-attachments/assets/b458b8eb-1446-45dd-913e-4b2020c081dd) |  |

| 設定画面 | 設定画面 |
| --- | --- |
| ![設定画面](https://github.com/user-attachments/assets/cfb03d52-f109-4c15-830c-a2a4bf22217c) | ![設定画面](https://github.com/user-attachments/assets/bc1460df-85b6-4c2c-a5f2-0b0971c5ac90) |


## 主な機能
- **音符計算ページ**  
  設定した時間単位で各音符の長さを計算できます。  
  - 音符計算ページのカードをタップすると、**メトロノームページ**が開きます。
    
- **メトロノームページ**  
  音符換算ページでタップしたカードの音符に合わせたメトロノームが再生されます。  
  - 4分音符に変換したときのBPMが表示されます。
  - アプリがクラッシュする可能性があるので、最大BPMを制限できます。

- **音符回数ページ**  
  指定した時間内で、各音符が何回発生するかを計算できます。

- **音符換算ページ**  
  異なるBPMで音符を変換した場合、その新しいBPMを計算します。

- **設定画面**  
  以下のカスタマイズが可能です：  
  - **カスタム音符の追加**：好きな名前と長さで独自の音符を登録可能。  
  - **音符の表示/非表示**の切り替え。  
  - **デフォルトの時間単位**の設定。
  - **小数の桁数**の設定。
  - **メトロノームの最大BPM**の設定。
  - **+/-ボタンの増減値**の設定。

## ビルドについて
このプロジェクトは、GitHub Actionsでもビルド可能です。各自でリポジトリをフォークして試すこともできます。

### 手動ビルド手順

1. **Flutterをセットアップ**  
   Flutter SDKをインストールし、パスを通す。

2. **Android Studio、Xcodeなどをセットアップ**  
   必要なIDEやツールチェーンをインストールし、環境を構築する。

3. **言語ファイルを生成する**  
   ```bash
   flutter gen-l10n
   ```

4. **必要なパッケージを取得する**  
   ```bash
   flutter pub get
   ```

5. **ビルドコマンドを実行**  
   デバイスやターゲットプラットフォームに応じたビルドコマンドを実行する。例:  
   ```bash
   flutter build apk --release
   ```  
   または  
   ```bash
   flutter build ios --release
   ```

### 注意点
- リリースページにあるファイルは古い可能性があります。  
最新版を入手するには、リポジトリをフォークし、自分でビルドすることをおすすめします。

## プロジェクト概要
このプロジェクトは、Flutterを使用して開発されています。

## 各種音ゲーの判定幅メモ
### プロセカ

| 色          | ノーツ       | フリック     | ロング始点     | ロング終点         | ロング終点フリック   |
|-------------|--------------|--------------|----------------|--------------------|----------------------|
| **白**      | ±41.6ms      | ±41.6ms      | ±41.6ms        |                    |                      |
| **黄**      | ±55ms        | ±58.3ms      | ±55ms          | +66.6ms ～ -58.3ms | +66.6ms ～ -58.3ms   |
| **緑**      | ±41.6ms      |              | ±41.6ms        | +66.6ms ～ -58.3ms | +66.6ms ～ -58.3ms   |


### ユメステ
- **PERFECT+**  ±25ms
- **PERFECT**  ±40ms

### ガルパ
- **PERFECT**  ±41.67ms

### D4DJ グルミク
- **PERFECT(内部)** ±25ms
- **PERFECT** ±50ms?

### Deemo
- ±50ms

### Arcaea
- **PURE(内部)** ±25ms
- **PURE** ±50ms

### TAKUMI³
- **虹JUST** ±40ms
- **JUST** ±60ms

### Cytus / Cytus II
- **TP Perfect**  ±70ms

### KALPA
- **PERFECT**  ±67ms

### Phigros
- **通常モード Perfect**  ±80ms
- **課題モード Perfect**  ±40ms

### ミリシタ
- **PERFECT(OM)** ±28ms?
- **PERFECT(MM以下)** ±50ms?

### デレステ
- **PERFECT(Mas以上)** ±70ms?
