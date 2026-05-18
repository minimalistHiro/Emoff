---
name: sync-app-screens-to-sheets
description: emoffプロジェクトのAPP_SCREENS.mdをGoogleスプレッドシートの「画面構成」タブに同期する。「画面構成をシートに反映して」「APP_SCREENSを同期して」等の依頼が対象。
---

# Sync App Screens to Sheets

## 手順

```bash
python3 scripts/emoff_sheets.py app-screens
```

## 注意事項

- 画面構成・画面遷移に関する作業では `APP_SCREENS.md` と `SCREEN_DESIGN.md` をあわせて確認する。
