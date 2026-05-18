---
name: sync-archive-to-sheets
description: emoffプロジェクトのARCHIVED_IDEAS.mdをGoogleスプレッドシートの「アーカイブ」タブに同期する。「アーカイブをシートに反映して」「却下案をスプレッドシートに同期して」等の依頼が対象。
---

# Sync Archive to Sheets

## 手順

```bash
python3 scripts/emoff_sheets.py archive
```

## 注意事項

- `R-x` のIDは再利用しない。
- アーカイブ日と理由を必ず保持する。
