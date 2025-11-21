# Pismo 開発フェーズドキュメント

このディレクトリには、Pismo（旧: Cyrillic Japanese IME）の開発を**並列開発可能な複数のフェーズ**に分割したドキュメントが格納されています。

各エンジニアは担当フェーズのドキュメントを読み、独立して開発を進めることができます。

---

## 📚 ドキュメント一覧

### Phase 0: 全体アーキテクチャとセットアップ（必読）
**ファイル**: [`PHASE_0_ARCHITECTURE.md`](./PHASE_0_ARCHITECTURE.md)
**対象**: 全エンジニア
**内容**:
- プロジェクト概要
- 全体システムアーキテクチャ
- 技術スタック
- ディレクトリ構造
- 開発環境セットアップ
- コーディング規約
- API契約

**💡 重要**: すべてのエンジニアは、開発開始前に必ずこのドキュメントを読んでください。

---

### Phase 1: 基礎アーキテクチャとIME統合（✅ 完了）
**ファイル**: [`PHASE_1_FOUNDATION.md`](./PHASE_1_FOUNDATION.md)
**対象**: Phase 1担当エンジニア
**ステータス**: ✅ **完了済み**
**実装済みコンポーネント**:
- `DisplayedTextManager.swift` (190行)
- `CyrillicComposingText.swift` (171行)
- `CyrillicInputManager.swift` (345行)
- `KeyboardViewController.swift` (リファクタリング済み: 235行)

**内容**:
- iOS標準IMEプロトコル統合
- 入力履歴管理とDelete対応
- マネージャーベースアーキテクチャ
- 実装済み機能の詳細仕様
- テストケース

**次のフェーズへの接続点**:
- Phase 2で `CyrillicInputManager` に漢字変換エンジンを統合

---

### Phase 2: 漢字変換エンジン統合（🔜 未着手）
**ファイル**: [`PHASE_2_KANJI_CONVERSION.md`](./PHASE_2_KANJI_CONVERSION.md)
**対象**: Phase 2担当エンジニア（バックエンド/変換ロジック）
**ステータス**: 🔜 未着手
**前提条件**: Phase 1完了

**実装する機能**:
- azooKey KanaKanjiConverter 統合
- 辞書バンドル (~50MB)
- 候補生成と表示
- ユーザー辞書と学習機能

**成果物**:
- `KanjiConversionEngine.swift` (~300行)
- `UserDictionary.swift` (~150行)
- `CyrillicInputManager.swift` (Phase 1から拡張)

**推定期間**: 2週間

**並列開発**: Phase 4と並列開発可能

---

### Phase 3: ライブ変換とインテリジェント入力（✅ 完了）
**ファイル**: [`PHASE_3_LIVE_CONVERSION.md`](./PHASE_3_LIVE_CONVERSION.md)
**対象**: Phase 3担当エンジニア（高度な変換ロジック）
**ステータス**: ✅ **完了済み**
**実装済みコンポーネント**:
- `LiveConversionManager.swift` (349行)
- `ClauseSegmenter.swift` (261行)
- `PredictiveEngine.swift` (301行)
- `KanjiConversionEngine.swift` (207行 - モック辞書実装)
- `Candidate.swift` (54行)

**実装済み機能**:
- リアルタイム自動変換
- 文節分割（Natural Language Framework）
- 文節選択と部分確定
- 予測変換（Bigramモデル）
- 学習機能（ユーザー辞書、頻度学習）

**次のフェーズへの接続点**:
- Phase 2で KanjiConversionEngine をazooKey実装に置き換え
- Phase 4で候補表示UIを強化

---

### Phase 4: 候補UI強化とインタラクション（🔜 未着手）
**ファイル**: [`PHASE_4_CANDIDATE_UI.md`](./PHASE_4_CANDIDATE_UI.md)
**対象**: Phase 4担当エンジニア（UI/UX専門）
**ステータス**: 🔜 未着手
**前提条件**: Phase 2完了（Phase 3とは独立）

**実装する機能**:
- 横スクロール候補バー
- 候補詳細表示（読み仮名、品詞）
- タッチジェスチャー（スワイプ）
- 数字キー選択（1～9）
- スムーズなアニメーション

**成果物**:
- `CandidateBarView.swift` (~300行)
- `CandidateCellView.swift` (~100行)
- `GestureHandler.swift` (~150行)

**推定期間**: 1.5週間

**並列開発**: Phase 2, Phase 3と並列開発可能

---

### Phase 5: プロファイル管理と設定機能（🔜 未着手）
**ファイル**: [`PHASE_5_PROFILES_SETTINGS.md`](./PHASE_5_PROFILES_SETTINGS.md)
**対象**: Phase 5担当エンジニア（メインアプリ開発、SwiftUI）
**ステータス**: 🔜 未着手
**前提条件**: Phase 1完了（他フェーズとは独立）

**実装する機能**:
- プロファイル選択画面（SwiftUI）
- プロファイル詳細とキー配列プレビュー
- 設定同期（App Groups）
- キーボードカスタマイズ設定
- ユーザー辞書管理（エクスポート/インポート）

**成果物**:
- `SettingsViewController.swift` (~400行)
- `ProfileListView.swift` (~200行)
- `ProfileDetailView.swift` (~250行)
- `UserDictionaryView.swift` (~200行)

**推定期間**: 1.5週間

**並列開発**: Phase 2, Phase 3, Phase 4と並列開発可能

---

## 🔄 フェーズ間の依存関係

```
Phase 0 (アーキテクチャ)
    ↓
Phase 1 (基礎実装) ← ✅ 完了
    ↓
    ├──→ Phase 2 (漢字変換) ──→ Phase 3 (ライブ変換)
    │           ↓
    │       Phase 4 (候補UI)
    │
    └──→ Phase 5 (設定画面)
```

### 並列開発の可能性

#### 同時開発可能な組み合わせ:
1. **Phase 2 + Phase 4**: Phase 2（変換エンジン）とPhase 4（UI）は異なるファイルで作業するため並列可能
2. **Phase 2 + Phase 5**: Phase 2（Keyboard Extension）とPhase 5（Main App）は別ターゲットなので並列可能
3. **Phase 3 + Phase 4**: Phase 3（変換ロジック）とPhase 4（UI）は独立しているため並列可能
4. **Phase 4 + Phase 5**: 完全に独立

#### 直列開発が必要な組み合わせ:
1. **Phase 1 → Phase 2**: Phase 2はPhase 1のマネージャーに依存
2. **Phase 2 → Phase 3**: Phase 3はPhase 2の変換エンジンに依存

---

## 👥 推奨チーム構成

### 最小構成（3名）
- **エンジニアA**: Phase 1（完了）→ Phase 2 → Phase 3
- **エンジニアB**: Phase 4
- **エンジニアC**: Phase 5

### 理想構成（5名）
- **エンジニアA**: Phase 1（完了）→ Phase 2コアロジック
- **エンジニアB**: Phase 2学習機能 → Phase 3予測変換
- **エンジニアC**: Phase 3ライブ変換 → Phase 3文節分割
- **エンジニアD**: Phase 4候補UI（全体）
- **エンジニアE**: Phase 5設定画面（全体）

---

## 📅 推奨スケジュール

### 8週間プラン（3名体制）

| 週 | エンジニアA | エンジニアB | エンジニアC |
|----|------------|------------|------------|
| 1-2 | Phase 2前半 | Phase 4前半 | Phase 5前半 |
| 3-4 | Phase 2後半 | Phase 4後半 | Phase 5後半 |
| 5-6 | Phase 3前半 | 統合テスト | 統合テスト |
| 7-8 | Phase 3後半 | 最終調整 | 最終調整 |

### 6週間プラン（5名体制）

| 週 | A | B | C | D | E |
|----|---|---|---|---|---|
| 1-2 | Phase 2コア | Phase 2学習 | Phase 3準備 | Phase 4 | Phase 5 |
| 3-4 | Phase 3サポート | Phase 3予測 | Phase 3ライブ | 統合 | 統合 |
| 5-6 | 統合テスト | 統合テスト | 統合テスト | 統合テスト | 統合テスト |

---

## 🛠 開発開始前のチェックリスト

各エンジニアは以下を確認してから開発を開始してください:

### すべてのエンジニア
- [ ] `PHASE_0_ARCHITECTURE.md` を読んだ
- [ ] 開発環境をセットアップした（Xcode, XcodeGen, Rust）
- [ ] プロジェクトがビルドできることを確認した
- [ ] Git のブランチ戦略を理解した

### Phase 2担当
- [ ] `PHASE_1_FOUNDATION.md` を読んだ
- [ ] `CyrillicInputManager.swift` の既存実装を理解した
- [ ] azooKey のドキュメントを読んだ
- [ ] 辞書ファイルのダウンロード方法を確認した

### Phase 3担当
- [ ] `PHASE_2_KANJI_CONVERSION.md` を読んだ
- [ ] `KanjiConversionEngine` のAPIを理解した
- [ ] Natural Language Framework のドキュメントを読んだ

### Phase 4担当
- [ ] `PHASE_2_KANJI_CONVERSION.md` を読んだ（Candidateモデル）
- [ ] UICollectionView のベストプラクティスを確認した
- [ ] アニメーションのパフォーマンス指標を理解した

### Phase 5担当
- [ ] `PHASE_1_FOUNDATION.md` を読んだ（ProfileManager）
- [ ] SwiftUI の基本を理解した
- [ ] App Groups の設定方法を確認した

---

## 📞 連絡とコミュニケーション

### 質問の優先順位
1. まず担当フェーズのドキュメントを読む
2. `PHASE_0_ARCHITECTURE.md` で全体像を確認
3. 既存コードを読む
4. それでも不明な場合、チーム内で質問

### コードレビュー
各フェーズの完了基準（Acceptance Criteria）を満たしているか確認:
- ✅ すべての機能完了基準を満たしている
- ✅ ユニットテストが書かれている
- ✅ コーディング規約に準拠している
- ✅ ドキュメンテーションが追加されている

---

## 🎯 最終目標

すべてのフェーズが完了すると、以下が実現されます:

1. ✅ キリル文字 → 日本語平仮名変換（Phase 1）
2. ✅ 平仮名 → 漢字変換（Phase 2）
3. ✅ リアルタイム自動変換（Phase 3）
4. ✅ 美しく直感的な候補UI（Phase 4）
5. ✅ プロファイル管理と設定画面（Phase 5）

**= 実用的で高品質な日本語IME 🚀**

---

## 📖 参考資料

### 必読ドキュメント
- `docs/要件定義書.md` - プロジェクト要件
- `docs/アプリ設計書.md` - 詳細設計
- `docs/cyrillicJapaneseInput.xlsx` - 変換仕様

### 参考実装
- `docs/repos/azooKey/` - 日本語IMEの参考実装
- `docs/repos/JapaneseKeyboardKit/` - Mozc統合の参考

### 外部リソース
- [Apple UIInputViewController](https://developer.apple.com/documentation/uikit/uiinputviewcontroller)
- [azooKey GitHub](https://github.com/ensan-hcl/azooKey)
- [Natural Language Framework](https://developer.apple.com/documentation/naturallanguage)

---

**Happy Coding! 🎉**

各フェーズのドキュメントを読んで、素晴らしいIMEを作りましょう！
