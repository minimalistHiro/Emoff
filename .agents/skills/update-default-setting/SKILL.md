---
name: update-default-setting
description: emoffプロジェクトでFree上限、Pro機能、原文保存期間、RevenueCat商品IDなどのデフォルト設定値を、コード・Markdown・スプレッドシートに一貫反映する。「デフォルト値を変更して」「送信上限を変更して」等の依頼が対象。
---

# Update Default Setting

## 手順

1. `DEFAULT_SETTINGS.md`、`BUSINESS_MODEL.md`、該当実装コードを確認する。
2. 設定値のSingle Source of Truthを特定する。
3. コード、仕様MD、必要ならQAを更新する。
4. `sync-default-settings-to-sheets` を実行する。

## 注意事項

- `DEFAULT_SETTINGS.md` をSingle Source of Truthの候補として扱い、変更後は同期する。
- 課金・保存期間・AI利用に関わる変更は `legal-docs-check` も確認する。
