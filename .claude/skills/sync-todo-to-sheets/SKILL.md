---
name: sync-todo-to-sheets
description: emoffプロジェクトのTODO.mdをGoogleスプレッドシートの「TODO」タブに同期する。「TODOをスプレッドシートに反映して」「TODOをシートに同期して」等の依頼が対象。
---

# Sync TODO to Sheets

## 概要

`TODO.md` の `ID / 優先度 / 内容 / 状態` テーブルをGoogleスプレッドシートへ反映する。

## 手順

```bash
python3 scripts/emoff_sheets.py todo
```

## 注意事項

- EmoffのTODOはYamaGoと列構成が異なるため、`scripts/emoff_sheets.py` のEmoff専用パーサーを使う。
- TODOの追加や完了処理は `todo-add` / `todo-add-interactive` / `todo-complete` を優先する。
