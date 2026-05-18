---
name: qa-spreadsheet-sync
description: emoffプロジェクトのqa/QA_V*.mdをGoogleスプレッドシートのQA_Vx.x.xタブへ同期する。「QAをスプレッドシートに反映して」「テストシートを作成して」「QAシートを更新して」等の依頼が対象。
---

# QA Spreadsheet Sync

## 手順

1. `qa-checklist-rules` を確認する。
2. `pubspec.yaml` のバージョンと `qa/QA_V{version}.md` の存在を確認する。
3. 次を実行する。

```bash
python3 scripts/emoff_sheets.py qa
```

バージョン指定:

```bash
python3 scripts/emoff_sheets.py qa --version 1.0.0
```

## 注意事項

- `qa/` が未作成の場合は、先にバージョン別QAファイルを作成する。
- スプレッドシートの手動入力を消す可能性がある操作では、実行前にユーザーへ確認する。
