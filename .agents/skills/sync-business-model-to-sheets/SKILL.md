---
name: sync-business-model-to-sheets
description: emoffプロジェクトのBUSINESS_MODEL.mdをGoogleスプレッドシートの「ビジネスモデル」タブに同期する。「ビジネスモデルをシートに反映して」「収益モデルをスプレッドシートに同期して」等の依頼が対象。
---

# Sync Business Model to Sheets

## 手順

```bash
python3 scripts/emoff_sheets.py business-model
```

## 注意事項

- ビジネスモデル、収益モデル、KPIに関する編集前後は `BUSINESS_MODEL.md` を正とする。
- 競合分析や市場規模など未決定の論点は必要に応じて `REVIEW_ITEMS.md` へ切り出す。
