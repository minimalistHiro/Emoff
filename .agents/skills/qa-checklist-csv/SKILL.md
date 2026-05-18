---
name: qa-checklist-csv
description: emoffプロジェクトのqa/QA_V*.mdをCSV形式に変換する。「QAチェックリストをCSVにして」「テスト用CSVを出して」「チェックリストをCSV化して」等の依頼が対象。
---

# QA Checklist CSV

## 手順

```bash
python3 scripts/emoff_sheets.py qa-csv
```

バージョン指定:

```bash
python3 scripts/emoff_sheets.py qa-csv --version 1.0.0
```

## 注意事項

- 出力先はプロジェクト直下の `QA_Vx.x.x.csv`。
