---
name: qa-csv-import
description: emoffプロジェクトでテスター記入済みCSVを受け取り、QA_RESULTS.mdやqa/QA_V*.mdへ反映する。「CSVを取り込んで」「テスト結果を反映して」「QA結果を更新して」等の依頼が対象。
---

# QA CSV Import

## 手順

1. `qa-checklist-rules` を確認する。
2. CSVの列が `テストID / 担当者 / 結果 / 実施日 / メモ` を識別できるか確認する。
3. `QA_RESULTS.md` に確定結果を追記する。
4. Pass済み項目は該当 `qa/QA_V*.md` のチェックボックスを更新する。

## 注意事項

- CSV形式が曖昧な場合は、列対応をユーザーへ確認する。
- Fail項目は勝手に完了扱いにしない。
