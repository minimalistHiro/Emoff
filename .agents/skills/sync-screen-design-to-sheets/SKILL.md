---
name: sync-screen-design-to-sheets
description: emoffプロジェクトのSCREEN_DESIGN.mdをGoogleスプレッドシートの「画面設計」タブに同期する。「画面設計をシートに反映して」「SCREEN_DESIGNを同期して」等の依頼が対象。
---

# Sync Screen Design to Sheets

## 手順

```bash
python3 scripts/emoff_sheets.py screen-design
```

## 注意事項

- UIやUX変更を伴う場合は先に `UI_UX.md` を確認する。
