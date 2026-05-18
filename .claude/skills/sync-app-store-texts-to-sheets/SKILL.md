---
name: sync-app-store-texts-to-sheets
description: emoffプロジェクトのAPP_STORE_TEXTS.mdをGoogleスプレッドシートの「ストア掲載文」タブに同期する。「ストア文言をシートに反映して」「APP_STORE_TEXTSを同期して」等の依頼が対象。
---

# Sync App Store Texts to Sheets

## 手順

```bash
python3 scripts/emoff_sheets.py app-store-texts
```

## 注意事項

- ストア文言更新時は `BUSINESS_MODEL.md`、`PRIVACY_POLICY.md`、`TERMS_OF_SERVICE.md` と矛盾しないよう確認する。
