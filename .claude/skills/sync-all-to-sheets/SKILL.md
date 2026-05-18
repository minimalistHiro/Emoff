---
name: sync-all-to-sheets
description: emoffプロジェクトの主要Markdownドキュメント、TODO、要検討事項、QAをGoogleスプレッドシートへ一括同期する。「スプレッドシートを同期して」「シートを全部更新して」「ドキュメントをスプレッドシートに反映して」等の依頼が対象。
---

# Sync All to Sheets

## 概要

Emoffの運用ドキュメントをGoogleスプレッドシートへ一括反映するオーケストレータ。

## 手順

1. `scripts/credentials.json` と `EMOFF_SPREADSHEET_ID` または `scripts/sheets_config.json` の設定を確認する。
2. `/Users/kanekohiroki/Desktop/emoff` で次を実行する。

```bash
python3 scripts/emoff_sheets.py all
```

3. 出力された同期対象と件数を報告する。

## 注意事項

- Google Sheetsへ書き込む前に、外部サービス書き込みの承認が必要な環境では承認を取る。
- 画像生成系スキルはこの一括同期の対象外。
