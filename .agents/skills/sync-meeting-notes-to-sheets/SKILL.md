---
name: sync-meeting-notes-to-sheets
description: emoffプロジェクトのmeeting_notes/配下の議事録をGoogleスプレッドシートに日付別タブで同期する。「議事録をシートに反映して」「会議メモをスプレッドシートに同期して」等の依頼が対象。
---

# Sync Meeting Notes to Sheets

## 手順

1. `meeting_notes/` が存在するか確認する。なければ作成方針をユーザーに確認する。
2. 次を実行する。

```bash
python3 scripts/emoff_sheets.py meeting-notes
```

## 注意事項

- 議事録からTODOや要検討事項へ反映する場合は `meeting-minutes-full` を使う。
