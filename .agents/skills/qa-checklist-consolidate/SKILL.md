---
name: qa-checklist-consolidate
description: emoffプロジェクトのQAチェックリストの重複・類似項目を検出し、統合案を提示する。「QA項目を整理して」「チェックリストを統合して」「テスト項目の重複を見て」等の依頼が対象。
---

# QA Checklist Consolidate

## 手順

1. `qa-checklist-rules` を確認する。
2. 対象の `qa/QA_V*.md` を読み込む。
3. 同じ画面・同じ操作・同じ期待結果の項目を候補としてまとめる。
4. 統合案をユーザーに提示し、承認後に編集する。

## 注意事項

- 承認なしにQA項目を削除しない。
- 統合した項目は必要に応じて `<!-- exclude_from_sheet: ... -->` のような除外メモで履歴を残す。
