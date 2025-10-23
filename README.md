# Cyrillic IME for Japanese

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/example/cyrillic-ime)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

キリル文字配列を用いて日本語（ひらがな）を入力するための、クロスプラットフォームIME（インプット・メソッド・エディタ）。

## 1. 思想と目的 (Philosophy & Purpose)

本プロジェクトは、単なる日本語入力ツールではない。これは、**「キリル文字は単一の文化圏の所有物ではなく、多様な言語的文脈で適応・進化したインターフェースである」**という事実を、入力体験そのものを通じて実証する試みである。

* **学習の促進**: 日本語話者がキリル文字（ロシア語、セルビア語、ウクライナ語など）のキー配列を学習するためのツールとして機能する。
* **多様性の実証**: ユーザーが「言語プロファイル」を切り替える（例: ロシア語 $\rightarrow$ セルビア語）ことで、同じ「ち (`[chi]`)」の音を入力するために押すキーが `ЧИ` から `Ћ` に変わる体験を通じ、文字体系の多様性を体感させる。

## 2. 特徴 (Features)

* **多プロファイル対応**: ロシア語、セルビア語、ウクライナ語、分析モードなど、複数のキリル文字配列（スキーマ）を動的に切り替え可能。
* **ハイブリッド・ネイティブアーキテクチャ**: 変換ロジック（Core）を **Rust** で記述し、UI（Shell）を **Swift (iOS)** と **Kotlin (Android)** で実装。これにより、ネイティブ同等のパフォーマンスとロジックの保守性（DRY原則）を両立する。
* **完全オフライン動作**: 全ての変換ロジック（JSONスキーマ）はアプリ本体に同梱（ネイティブ・バンドル）。インストール後は一切のネットワーク通信を必要としない。
* **ハイパフォーマンス**: 入力バッファ管理と変換ロジックは全てメモリ上で完結し、ネイティブIMEに匹敵する低遅延（Low Latency）を実現する。

## 3. 技術スタック (Tech Stack)

* **Core Engine**: **Rust**
    * `serde_json`: 変換スキーマ（JSON）のパースとメモリ展開。
    * `HashMap`: メモリ上での高速な辞書ルックアップ。
* **iOS**: **Swift** (SwiftUI / UIKit)
    * `UIInputViewController`: iOSキーボード拡張機能。
    * `Swift Package Manager`: Rustコアライブラリ（`.xcframework`）の連携。
* **Android**: **Kotlin** (Jetpack Compose / XML)
    * `InputMethodService`: Androidキーボードサービス。
    * `JNI (Java Native Interface)`: Rustコアライブラリ（`.so`）の連携。

## 4. ビルドとセットアップ (Build & Setup)

*TBD (To Be Defined)*

（概要）
1.  Rust Core (`cyrillic_ime_core`) のビルド環境をセットアップする。
2.  `cargo-lipo` (iOS) および `cargo-ndk` (Android) を使用し、Rust Coreを各プラットフォーム向けのバイナリ（`.a` / `.so`）としてクロスコンパイルする。
3.  ネイティブプロジェクト (Xcode / Android Studio) で、生成されたバイナリをリンクする。

## 5. 貢献 (Contribution)

変換スキーマ（`schemas/*.json`）の改善、新しい言語プロファイル（例: ブルガリア語、モンゴル語）の追加、ローカルな入力方法に関するフィードバックは、GitHubのIssuesにて歓迎する。
