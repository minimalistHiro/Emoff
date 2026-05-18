---
name: sync-review-items-to-sheets
description: emoffプロジェクトのREVIEW_ITEMS.mdをGoogleスプレッドシートの「要検討事項」タブに同期する。「要検討事項をシートに反映して」「検討事項をスプレッドシートに同期して」等の依頼が対象。
---

# Sync Review Items to Sheets

## 概要

`REVIEW_ITEMS.md` の `R-x` ブロックを読み取り、優先度・カテゴリ・内容・状態をシートへ反映する。

## 手順

```bash
python3 scripts/emoff_sheets.py review
```

## 注意事項

- 却下・凍結・不要になった項目は削除せず、`archive-organize` で `ARCHIVED_IDEAS.md` に移動する。
