---
name: sync-default-settings-to-sheets
description: emoffプロジェクトのDEFAULT_SETTINGS.mdをGoogleスプレッドシートの「デフォルト設定値」タブに同期する。「デフォルト設定をシートに反映して」「初期値をスプレッドシートに同期して」等の依頼が対象。
---

# Sync Default Settings to Sheets

## 手順

1. `DEFAULT_SETTINGS.md` が存在するか確認する。
2. 次を実行する。

```bash
python3 scripts/emoff_sheets.py default-settings
```

## 注意事項

- Free上限、Pro機能、原文保存期間、RevenueCat商品IDなどを更新した場合は、関連するコード・仕様MD・法務文書との整合も確認する。
