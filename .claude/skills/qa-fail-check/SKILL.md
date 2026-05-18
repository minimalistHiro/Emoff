---
name: qa-fail-check
description: emoffプロジェクトのQAスプレッドシートからFailまたは未実施項目を確認する。「失敗しているQAは？」「未完了のテストを見せて」「Fail項目を確認して」等の依頼が対象。
---

# QA Fail Check

## 手順

```bash
python3 scripts/emoff_sheets.py qa-fail
```

バージョン指定:

```bash
python3 scripts/emoff_sheets.py qa-fail --version 1.0.0
```

## 注意事項

- Failから修正TODOを作る場合は、既存TODOとCOMPLETEDを確認して重複を避ける。
