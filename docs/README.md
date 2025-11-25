# Pismo Documentation

Pismoプロジェクトのドキュメント

## Directory Structure

```
docs/
├── README.md                 # このファイル
├── appstore/                 # App Store関連
│   ├── asset_generation_prompts.md  # AI画像生成プロンプト
│   └── screenshots/          # スクリーンショット
├── development/              # 開発者向けドキュメント
│   ├── CONTRIBUTING.md       # コントリビューションガイド
│   ├── advice_for_azooKey_based_development.md
│   ├── ViterbiConversionEngine.md
│   ├── view_controller_memory_leak.md
│   └── tests.md
├── mappings/                 # キリル文字マッピング定義
│   ├── cyrillic_mapping_seion.csv      # 清音
│   ├── cyrillic_mapping_dakuten.csv    # 濁音
│   ├── cyrillic_mapping_youon.csv      # 拗音
│   ├── cyrillic_mapping_gairaigo.csv   # 外来語音
│   ├── cyrillic_mapping_special.csv    # 特殊
│   └── cyrillic_extension_requirements.csv  # 将来の拡張計画
├── policies/                 # プロジェクトポリシー
│   ├── dictionary.md
│   ├── emoji_and_kaomoji.md
│   ├── full_access.md
│   ├── ios_support.md
│   ├── localization.md
│   ├── theme.md
│   └── versioning.md
├── reference/                # リファレンス・仕様書
│   ├── overview.md
│   ├── settings.md
│   ├── clipboard_history.md
│   ├── keyboard_layout_behavior.md
│   ├── marked_text_notes.md
│   ├── 要件定義書.md
│   └── テスト仕様書.md
├── visions/                  # 将来ビジョン
│   ├── README.md
│   ├── custom_tab_vision.md
│   └── full_access.md
├── images/                   # ドキュメント用画像
├── repos/                    # 参照リポジトリ
└── cyrillicJapaneseInput.xlsx  # マッピング元データ
```

## Quick Links

- [開発ガイド](development/CONTRIBUTING.md)
- [App Storeアセット生成](appstore/asset_generation_prompts.md)
- [キリル文字マッピング](mappings/)
- [要件定義書](reference/要件定義書.md)
- [かな漢字変換モジュール](https://github.com/ensan-hcl/AzooKeyKanaKanjiConverter/tree/develop/Docs/)
