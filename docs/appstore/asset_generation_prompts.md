# App Store Asset Generation Prompts

Nano Banana (Google Gemini) を使用したApp Store用アセット生成のプロンプト集

## 使用方法

1. [Gemini App](https://gemini.google.com/) または [Google AI Studio](https://aistudio.google.com/) にアクセス
2. 「Create images」を選択
3. 以下のプロンプトをコピーして使用

---

## 1. App Icon (アプリアイコン)

### Required Sizes
- 1024x1024px (App Store)
- 180x180px (iPhone @3x)
- 120x120px (iPhone @2x)

### Prompt (English)

```
Create a minimalist app icon for "Pismo" - a Cyrillic-Japanese keyboard app for iOS.

Design requirements:
- Square format, 1024x1024 pixels
- Clean, modern, flat design style
- Primary colors: Deep purple (#6B4C9A) with white accents
- Show a stylized keyboard key with both Cyrillic "Ф" and Japanese "ひ" characters overlapping elegantly
- Subtle gradient background from deep purple to lighter purple
- No text except the characters on the key
- iOS app icon style with rounded corners
- Professional, trustworthy appearance
- High contrast for visibility at small sizes
```

### Prompt (Japanese)

```
「Pismo」というiOS向けキリル文字日本語キーボードアプリのアイコンを作成してください。

デザイン要件：
- 正方形、1024x1024ピクセル
- クリーンでモダンなフラットデザイン
- メインカラー：ディープパープル（#6B4C9A）と白のアクセント
- キリル文字「Ф」と日本語「ひ」が優雅に重なったスタイライズドキーボードキー
- ディープパープルからライトパープルへの微妙なグラデーション背景
- キー上の文字以外のテキストなし
- 角丸のiOSアプリアイコンスタイル
- プロフェッショナルで信頼感のある外観
- 小さいサイズでも視認性の高いコントラスト
```

---

## 2. App Store Screenshots

### Required Sizes
- iPhone 6.7" (1290 x 2796 px) - iPhone 15 Pro Max
- iPhone 6.5" (1284 x 2778 px) - iPhone 14 Plus
- iPhone 5.5" (1242 x 2208 px) - iPhone 8 Plus
- iPad Pro 12.9" (2048 x 2732 px)

### Screenshot 1: Main Keyboard View

```
Create a promotional screenshot for iOS App Store showing a Cyrillic keyboard app.

Scene: An iPhone 15 Pro displaying a messaging app with a Cyrillic keyboard visible at the bottom.
- The keyboard shows Russian Cyrillic letters (А Б В Г Д Е Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я)
- Clean, modern iOS keyboard design with slight shadows
- Above the keyboard, show a conversation with Japanese text converted from Cyrillic input
- Example: "привет" → "ぷりうぃぇっと"
- Dark mode interface
- Headline text at top: "キリル文字で日本語入力"
- Subtext: "Cyrillic → Japanese Conversion"
- Size: 1290 x 2796 pixels
- Professional marketing quality
```

### Screenshot 2: Multi-Language Support

```
Create an iOS App Store screenshot showing keyboard language options.

Scene: iPhone settings screen showing available Cyrillic keyboard variants:
- Russian (Русский)
- Ukrainian (Українська)
- Bulgarian (Български)
- Serbian (Српски)
- Belarusian (Беларуская)

Each option with a checkmark icon and flag emoji.
- Clean iOS Settings style interface
- Headline: "5 Languages Supported"
- Subtitle: "Russian, Ukrainian, Bulgarian, Serbian, Belarusian"
- Size: 1290 x 2796 pixels
- Light mode, professional appearance
```

### Screenshot 3: Live Conversion Demo

```
Create an iOS App Store screenshot demonstrating live text conversion.

Scene: Split view showing:
- Top half: Cyrillic input being typed "Москва"
- Bottom half: Real-time Japanese output "もすくゔぁ"
- Arrow animation between them suggesting conversion
- Keyboard visible at bottom with highlighted keys
- Headline: "リアルタイム変換"
- Subtitle: "Live Conversion Technology"
- Smooth gradient background (purple to blue)
- Size: 1290 x 2796 pixels
```

### Screenshot 4: Features Overview

```
Create an iOS App Store screenshot showing app features as icons.

Design: 2x3 grid of feature icons with labels:
1. Globe icon - "5 Languages"
2. Lightning bolt - "Live Conversion"
3. Keyboard icon - "QWERTY Layout"
4. Shield icon - "Privacy First"
5. Paintbrush icon - "Custom Themes"
6. Star icon - "Open Source"

- Each icon in a rounded square card
- Purple accent color (#6B4C9A)
- White background
- Headline at top: "All Features"
- Clean, minimal iOS design
- Size: 1290 x 2796 pixels
```

### Screenshot 5: Usage Example

```
Create an iOS App Store screenshot showing practical usage.

Scene: Notes app with Japanese text written using Cyrillic keyboard:
- Title: "日本語メモ"
- Content showing example sentences:
  "こんにちは" (from Коннитиха)
  "ありがとう" (from Аригатоу)
  "さようなら" (from Саёунара)
- Keyboard partially visible at bottom
- Soft, friendly pastel background
- Headline: "簡単に日本語入力"
- Subtitle: "Easy Japanese Input"
- Size: 1290 x 2796 pixels
```

---

## 3. Feature Graphics (Optional)

### App Store Preview Poster

```
Create a wide banner image for app promotion.

Design:
- Size: 2208 x 1242 pixels (landscape)
- Show iPhone mockup with Cyrillic keyboard displayed
- App name "Pismo" in elegant typography
- Tagline: "Type Japanese with Cyrillic"
- Japanese translation below: 「キリル文字で日本語を」
- Gradient background from deep purple to light purple
- Floating Cyrillic and Japanese characters as decorative elements
- Professional, clean marketing style
```

---

## 4. Color Palette

アセット生成時に使用する統一カラーパレット：

| Name | Hex | Usage |
|------|-----|-------|
| Primary Purple | #6B4C9A | Main accent |
| Light Purple | #9B7DC5 | Gradients |
| Dark Purple | #4A3468 | Text, shadows |
| White | #FFFFFF | Backgrounds |
| Light Gray | #F5F5F7 | Secondary BG |
| Text Black | #1D1D1F | Primary text |

---

## 5. Typography Guidelines

- Headlines: SF Pro Display Bold
- Body: SF Pro Text Regular
- Japanese: Hiragino Sans
- Cyrillic: System default

---

## 6. Export Checklist

### App Icon
- [ ] 1024x1024 (App Store Connect)
- [ ] 180x180 (@3x)
- [ ] 120x120 (@2x)
- [ ] 60x60 (@1x)

### Screenshots
- [ ] iPhone 6.7" (1290 x 2796) - 最低3枚
- [ ] iPhone 6.5" (1284 x 2778)
- [ ] iPhone 5.5" (1242 x 2208)
- [ ] iPad Pro 12.9" (2048 x 2732) - オプション

### Preview Video (Optional)
- [ ] 30秒以内
- [ ] 1920x886 または 886x1920

---

## Notes

- Nano Banana (Gemini) で生成した画像は、必要に応じて Figma や Photoshop で微調整
- テキストの読みやすさを確認（特に小さいアイコンサイズ）
- App Store Review Guidelines に準拠していることを確認
- スクリーンショットは実際のアプリ画面を基に作成することを推奨

## References

- [Nano Banana (Google Gemini)](https://gemini.google.com/)
- [App Store Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)
- [Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
