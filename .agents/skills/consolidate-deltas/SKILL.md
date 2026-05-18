---
name: consolidate-deltas
description: emoffプロジェクトでバッチ実装後のplans/in_progress/*_delta.mdを集約し、TODO.md、COMPLETED.md、qa/QA_V*.md、仕様MDに反映する。「deltaを統合して」「バッチ差分をまとめて」等の依頼が対象。
---

# Consolidate Deltas

## 手順

1. `plans/in_progress/*_delta.md` を一覧化する。
2. TODO完了、QA追加、仕様変更、要検討事項を分類する。
3. `TODO.md`、`COMPLETED.md`、`qa/QA_V*.md`、関連仕様MDへ反映する。
4. 反映済みdeltaを `plans/completed/` へ移す方針をユーザーに確認する。

## 注意事項

- deltaの内容を無批判に反映せず、現行仕様と矛盾しないか確認する。
