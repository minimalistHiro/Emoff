---
name: sync-firestore-to-sheets
description: emoffプロジェクトのFIRESTORE.mdをGoogleスプレッドシートの「Firestore」タブに同期する。「Firestore設計をシートに反映して」「FIRESTOREを同期して」等の依頼が対象。
---

# Sync Firestore to Sheets

## 手順

```bash
python3 scripts/emoff_sheets.py firestore
```

## 注意事項

- Firestoreスキーマ・セキュリティルールに関する作業では `firestore-schema-check` も参照する。
