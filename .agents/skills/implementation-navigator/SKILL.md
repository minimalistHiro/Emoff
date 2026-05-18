---
name: implementation-navigator
description: emoffプロジェクトで設計済み画面の実装を段階的に進めるためのナビゲーター。「次に進めるべき実装は？」「実装の進捗は？」「次の実装は？」「どこまで実装した？」等の依頼が来たときに、IMPLEMENTATION_PROGRESS.mdと設計書を読み込み、次に実装すべき画面と手順を案内する。
---

# Implementation Navigator

## 概要

設計完了済みの画面を1画面ずつ段階的に実装していくためのナビゲーションスキル。
進捗管理ファイル（IMPLEMENTATION_PROGRESS.md）を起点に、次に実装すべき画面の特定・設計書の読み込み・実装作業のガイドを行う。

## 手順

### ステップ1: 現状把握（必ず最初に実行）

以下のファイルを Read ツールで読み込む:

1. `/Users/kanekohiroki/Desktop/emoff/IMPLEMENTATION_PROGRESS.md` — 実装進捗の確認
2. `/Users/kanekohiroki/Desktop/emoff/DESIGN_PROGRESS.md` — 設計進捗の確認（新たに設計完了した画面がないかチェック）
3. `/Users/kanekohiroki/Desktop/emoff/REVIEW_ITEMS.md` — 未決定事項・ブロッカーの確認

### ステップ2: 新規設計完了画面の同期

DESIGN_PROGRESS.md に新たに `[x] 完了` となった画面があり、IMPLEMENTATION_PROGRESS.md に未登録の場合:

1. 該当画面を IMPLEMENTATION_PROGRESS.md の適切なフェーズに追加する
2. サマリーテーブルの数値を更新する

### ステップ3: 次の実装対象を特定

IMPLEMENTATION_PROGRESS.md の実装進捗テーブルから、以下の優先順で次の実装対象を特定する:

1. `[ ] 進行中` の項目があれば、それを最優先で継続
2. なければ、現在のフェーズ内で `[ ] 未着手` かつブロッカーなしの項目を順番に選択
3. フェーズ内の全項目が完了していれば、次のフェーズに進む
4. `[!] ブロック中` の項目がある場合、ブロッカーの解決を先に提案する

**フェーズ0（基盤構築）は個別画面より常に優先する。**

### ステップ4: 実装対象の関連情報を読み込む

次の実装対象が決まったら、以下のファイルを Read ツールで読み込む:

1. 対象画面の設計書（`plans/in_progress/` 内） — 実装仕様の確認
2. `/Users/kanekohiroki/Desktop/emoff/FIRESTORE.md` — データ構造・クエリ・セキュリティルール
3. `/Users/kanekohiroki/Desktop/emoff/UI_UX.md` — デザインルール・共通コンポーネント
4. `/Users/kanekohiroki/Desktop/emoff/BUSINESS_MODEL.md` — 仕様・プラン制約
5. `lib/` 内の既存コード — 実装済み画面・サービスとの整合性確認

### ステップ5: ユーザーに報告・提案

以下の形式で報告する:

```
## 現在の実装進捗
- フェーズX: Y/Z 完了
- 全体: A/B 完了

## 次の実装対象
**項目名**: 〇〇
**フェーズ**: X（〇〇）
**設計書**: `plans/in_progress/XXXXXXXX_xxx_design.md`

## 事前確認事項
- （ブロッカーがあれば記載。なければ「なし」）
- （未決定事項で先に決めるべきことがあれば記載）

## 設計書の要点
- 主なUI要素: ...
- Firestoreコレクション: ...
- インタラクション: ...

## 実装方針
- 作成するファイル: ...
- 使用する共通コンポーネント: ...
- 注意点: ...

## 進め方
このまま実装を開始しますか？
```

### ステップ6: 実装の実行

ユーザーから承認を得たら:

1. 設計書の仕様に忠実に従ってコードを実装する
2. UI_UX.md のルールを遵守する:
   - ボタン → `CustomButton`（primary / secondary / danger）
   - ダイアログ → `CustomDialog` / `custom_dialog_helper.dart`
   - テキスト入力 → `CustomTextField`
   - AppBar → `CustomAppBar`
   - ローディング → `CustomLoadingIndicator`
   - スナックバーは使用禁止
3. Firestoreのフィールド名・クエリはFIRESTORE.mdに準拠する
4. カラーパレット・フォントはUI_UX.mdに準拠する
5. iPhone SE（375×667）でのレイアウト確認を意識する

### ステップ7: 完了処理

実装が完了し、ユーザーの確認を得たら:

1. IMPLEMENTATION_PROGRESS.md の該当行の状態を `[x] 完了（日付）` に更新する
2. IMPLEMENTATION_PROGRESS.md のサマリーテーブルの数値を更新する
3. IMPLEMENTATION_PROGRESS.md の実装ログに記録を追加する
4. 設計書を `plans/in_progress/` → `plans/completed/` に移動する（`git mv` を使用）
5. APP_SCREENS.md の該当画面の設計書パスを `plans/completed/` のパスに更新する

## 対象となる依頼例

- 次に進めるべき実装は？
- 実装の進捗は？
- 次の実装は？
- どこまで実装した？
- 実装を進めて
- 〇〇画面を実装して
- 実装の状況を確認して
- 次の画面を実装しよう

## 注意事項

- 1回のスレッドで扱う画面は原則1画面とする（品質の維持）
- **設計書が存在しない画面は実装しない。** 先に design-navigator で設計を完了させるよう案内する
- ブロッカーがある項目は、ブロッカーの解決を先に行う
- 実装中に設計書の仕様に不明点・矛盾がある場合は、ユーザーに確認する（勝手に解釈しない）
- 実装中に新たな未決定事項が出た場合は、REVIEW_ITEMS.md に追加する
- 「進行中」の項目がスレッドをまたぐ場合は、IMPLEMENTATION_PROGRESS.md に作業メモを残す
- フェーズ0（基盤構築）の項目には設計書がないが、FIRESTORE.md・UI_UX.md・BUSINESS_MODEL.md を参照して実装する
