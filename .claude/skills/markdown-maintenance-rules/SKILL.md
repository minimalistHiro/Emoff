---
name: markdown-maintenance-rules
description: 「マークダウンを整理して」「ドキュメントを更新して」「MDファイルを整理して」など、プロジェクトのマークダウンドキュメントの整理・更新を依頼されたときに使う。
---

# Markdown Maintenance Rules

## 概要

emoffプロジェクトの各種マークダウンドキュメントを、直近の変更内容に基づいて整理・追記・修正する。

## 手順

ユーザーから「マークダウンを整理して」「ドキュメントを更新して」などの依頼があったら、以下の手順を順に実行する。

1. `/Users/kanekohiroki/Desktop/emoff/BUSINESS_MODEL.md` を読み込み、今回の変更にビジネスモデル・収益モデル・事業戦略・KPI等の変更がある場合は、BUSINESS_MODEL.md を追記・修正する。
2. `/Users/kanekohiroki/Desktop/emoff/FIRESTORE.md` を読み込み、Firestore関連（コレクション/ドキュメントの作成・削除・更新、セキュリティルール変更など）の変更がある場合は、FIRESTORE.md を追記・修正する。
3. `/Users/kanekohiroki/Desktop/emoff/APP_SCREENS.md` を読み込み、今回の変更に画面の作成・変更・削除等がある場合は、APP_SCREENS.md を追記・修正する。
   - **【重要】APP_SCREENS.md には実装済みの画面・コンポーネントのみを記載する。**
   - 未実装・計画中の画面は記載しない。実装が完了してから追記すること。
4. `/Users/kanekohiroki/Desktop/emoff/TODO.md` と `/Users/kanekohiroki/Desktop/emoff/COMPLETED.md` を確認し、以下を実行する：
   - 今回の変更で完了したTODO項目がある場合、TODO.md から該当行を削除し、COMPLETED.md の該当日付セクション（`## YYYY-MM-DD`）に移動する。日付セクションが存在しない場合は新規作成する（降順: 新しい日付が上）。
   - 今回の変更で廃止になったTODO項目がある場合も同様に、TODO.md から削除し COMPLETED.md に移動する。備考欄に「**廃止**: 理由」を記載する。
   - 今回の変更で新たに必要になったTODO項目がある場合、TODO.md の適切なセクションに新規TODO項目を追記する。
5. `/Users/kanekohiroki/Desktop/emoff/REVIEW_ITEMS.md` を読み込み、今回の変更に関連する要検討事項・未決定事項がある場合は、REVIEW_ITEMS.md を追記・修正する：
   - 今回の変更によって新たに検討が必要になった事項がある場合、適切な優先度・カテゴリで新規項目を追記する。
   - 今回の変更によって決定済み・見送りになった項目がある場合、その項目を REVIEW_ITEMS.md から削除する。

## 判定ルール

- 各ドキュメントについて、変更が必要かどうかを判定する。
- 変更が必要な場合のみ追記・修正を行う。
- 変更が不要な場合は「変更不要」とその理由を報告する。
- 全てのドキュメントについて結果を一覧で報告する。

## 対象となる依頼例

- マークダウンを整理して
- ドキュメントを更新して
- MDファイルを整理して
- ドキュメントを最新化して
- 各種マークダウンを整理して
