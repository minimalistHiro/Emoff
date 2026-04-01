---
name: app-store-texts-update
description: emoffプロジェクトでアプリストア掲載テキストの更新・編集を依頼されたときに、BUSINESS_MODEL.mdを参照してAPP_STORE_TEXTS.mdを編集するために使う。「アプリストアテキストを更新して」「アプリストア提出用テキストを編集して」「ストアテキストを修正して」「App Storeの説明文を更新して」「Google Playの説明を直して」「ストア掲載文を更新して」等の依頼が対象。
---

# App Store Texts Update

## 概要

アプリストア掲載テキスト（`APP_STORE_TEXTS.md`）の更新・編集依頼が来たときに、`BUSINESS_MODEL.md` を参照して内容を確認し、`APP_STORE_TEXTS.md` を編集する。

## 手順

### 1. 両ファイルを読み込む

以下の2ファイルを Read ツールで同時に読み込む：

- `/Users/kanekohiroki/Desktop/emoff/BUSINESS_MODEL.md`
- `/Users/kanekohiroki/Desktop/emoff/APP_STORE_TEXTS.md`

### 2. ユーザーの依頼内容を確認する

ユーザーが「どこを」「どのように」変更したいかを確認する。

- 特定の項目（アプリ名・説明文・キーワードなど）を指定している場合 → そこだけ編集
- 「全体的に更新して」などの場合 → BUSINESS_MODEL.md の内容と照らし合わせて最新状態に整合させる
- 「〇〇を追加して」などの場合 → 指定の内容を追記する

### 3. 文字数制限を必ず守る

各項目の文字数・バイト数制限を遵守する：

| プラットフォーム | 項目 | 制限 |
|---|---|---|
| App Store | アプリ名 | 30文字以内 |
| App Store | サブタイトル | 30文字以内 |
| App Store | プロモーションテキスト | 170文字以内 |
| App Store | 説明文 | 4,000文字以内 |
| App Store | キーワード | 100バイト以内（UTF-8） |
| App Store | 更新情報 | 4,000文字以内 |
| Google Play | アプリ名 | 30文字以内 |
| Google Play | 簡単な説明 | 80文字以内 |
| Google Play | 詳細な説明 | 4,000文字以内 |

編集後は文字数（またはバイト数）を必ずカウントして、制限内に収まっていることを確認してから Edit ツールで書き込む。

### 4. Edit ツールで APP_STORE_TEXTS.md を編集する

- `/Users/kanekohiroki/Desktop/emoff/APP_STORE_TEXTS.md` を Edit ツールで編集する
- 変更箇所のみを編集し、他のセクションには手を加えない

### 5. 編集結果を日本語で報告する

- 変更した項目と内容を日本語で簡潔に報告する
- 文字数が制限に近い場合は注意として伝える

## 注意事項

- **文字数制限は厳守**。超過する場合はユーザーに相談して内容を削減する
- Google Playのアプリ名には「#1」「best」「free」「top」などランキング・価格を示す言葉は使用禁止
- キーワード（App Store）はカンマ区切り・スペースなし。日本語は1文字3バイト（UTF-8）でカウント
- BUSINESS_MODEL.md の内容と矛盾する記述を APP_STORE_TEXTS.md に含めないこと
- BUSINESS_MODEL.md に記載されていない未確定の仕様はテキストに含めないこと

## 対象となる依頼例

- アプリストアテキストを更新して
- アプリストア提出用テキストを編集して
- ストアテキストを修正して
- App Storeの説明文を更新して
- Google Playの説明を直して
- ストア掲載文を更新して
- キーワードを変更して
- 説明文を書き直して
