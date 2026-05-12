# AGENTS.md

このプロジェクトでのアシスタント応答ルール（Claude Code / Codex / Copilot 等の各種AIエージェント共通）。

## 共通ルール

- 返答は必ず日本語で行うこと。

## UI/UX の参照ルール

- 画面の作成・編集・デザイン変更など、UIやUXに関わる作業を行う際は、必ず **UI_UX.md** を事前に読み取ること。
- UI_UX.md に記載されている方針・ガイドラインに従って実装すること。

## ドキュメントの参照ルール

- ビジネスモデル・収益モデル・KPIに関する作業時は **BUSINESS_MODEL.md** を参照すること。
- 未決定事項・要検討事項に関する作業時は **REVIEW_ITEMS.md** を参照すること。
- 却下・凍結された過去アイデアの検索・復活時は **ARCHIVED_IDEAS.md** を参照すること。
- 画面構成・画面遷移に関する作業時は **APP_SCREENS.md** / **SCREEN_DESIGN.md** を参照すること。
- Firestore のスキーマ・セキュリティルールに関する作業時は **FIRESTORE.md** を参照すること。
- 未着手タスクに関する作業時は **TODO.md**、完了タスクに関する作業時は **COMPLETED.md** を参照すること。

## QA 関連のルール

- 実装が完了した項目（COMPLETED.md に移動された項目）に基づいて、対応するバージョンの `qa/QA_Vx.x.x.md` にチェック項目を追記する。
- テスト結果（Pass / Fail / Skip）は **QA_RESULTS.md** に追記して記録する。

## 要検討事項の運用ルール

- REVIEW_ITEMS.md から却下・凍結・不要となった項目は、削除せずに **ARCHIVED_IDEAS.md** に移動する。
- 将来再検討が必要になった場合は ARCHIVED_IDEAS.md から REVIEW_ITEMS.md に戻す。
