---
name: nano-banana-image-gen
description: 「画像を生成して」「画像を作って」「アイコンを作って」「バナーを作って」など、画像生成の依頼時に、Nano Banana Pro（Gemini 3 Pro Image）APIを使って画像を自動生成する。
---

# Nano Banana Pro 画像生成スキル

## 目的

ユーザーから画像生成を依頼されたときに、Nano Banana Pro（Gemini 3 Pro Image）APIを使って自動的に画像を生成する。

## 生成手順の参照

具体的な画像生成の手順（コマンド実行方法・保存先・アスペクト比の決定方法）は、以下のファイルを Read ツールで読み込んでから実行してください：

`/Users/kanekohiroki/Desktop/emoff/.claude/skills/nano-banana-image-gen/HOW_TO_GENERATE.md`

## 「画像を生成して」のデフォルトスタイル

ユーザーが「画像を生成して」「画像を作って」と依頼した場合（ロゴ・アイコン・バナーなどの具体的な種別指定がない場合）、以下のスタイルをプロンプトに必ず含める：

- **スタイル**: ダーク系モダンフラットデザイン（dark modern flat design illustration）
- **配色**: 黒・ダークグレー・シアン（`#00D4FF`）基調（black, dark gray, and cyan color palette）
- **線画**: クリーンでシンプルな線（clean simple outlines）
- **背景**: 黒またはダークグレー背景（black or dark background）
- **全体の雰囲気**: クールでミニマルなテック系デザイン

プロンプト例:
`"Dark modern flat design illustration of [シーンの内容], black and dark gray background, cyan accent color #00D4FF, clean simple outlines, cool minimal tech style, no gradients, professional"`

**適用条件**:
- 適用する: 「画像を生成して」「画像を作って」「〇〇の画像を生成して」など、画像の種別指定がない汎用的な依頼
- 適用しない: 「ロゴを作って」「アイコンを作って」「バナーを作って」「写真風に」など、具体的な種別やスタイル指定がある依頼

## プロンプト作成のコツ

- スタイルを明示する（例: "flat design", "minimalist", "dark theme"）
- emoffのブランドカラーを活用する（黒: `#0D0D0D`, シアン: `#00D4FF`）
- 背景を指定する（例: "on a dark background", "transparent background"）
- テキストを含める場合は引用符で囲む（例: 'with the text "emoff"'）
