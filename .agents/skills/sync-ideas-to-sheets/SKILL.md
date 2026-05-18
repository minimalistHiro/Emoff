---
name: sync-ideas-to-sheets
description: emoffプロジェクトのBUSINESS_IDEAS.mdをGoogleスプレッドシートの「ビジネスアイデア」タブに同期する。「アイデアをシートに反映して」「ビジネスアイデアをスプレッドシートに同期して」等の依頼が対象。
---

# Sync Ideas to Sheets

## 手順

```bash
python3 scripts/emoff_sheets.py ideas
```

## 注意事項

- 採用済みの内容は `BUSINESS_MODEL.md` へ移動する。
- 却下・凍結した案は `ARCHIVED_IDEAS.md` へ移動する。
