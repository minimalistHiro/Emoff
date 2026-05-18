---
name: organize-requirements
description: emoffプロジェクトでユーザー要望を整理し、仕様書・TODO・要検討事項への反映方針を作る。「要望を整理して」「依頼をまとめて」「仕様に落とし込んで」等の依頼が対象。
---

# Organize Requirements

## 読み込むファイル

- `BUSINESS_MODEL.md`
- `APP_SCREENS.md`
- `SCREEN_DESIGN.md`
- `FIRESTORE.md`
- `UI_UX.md`
- `REVIEW_ITEMS.md`
- `TODO.md`
- `COMPLETED.md`
- `PRIVACY_POLICY.md`
- `TERMS_OF_SERVICE.md`

## 手順

1. 要望を機能、UI、データ、課金、法務、運用に分ける。
2. 既存仕様と矛盾する箇所を示す。
3. 実装可能なものはTODO候補、未決定のものはREVIEW候補に分ける。
4. 仕様MDの更新が必要な場合は対象ファイルを明示する。

## 注意事項

- 法務・AI処理・保存期間に触れる要望は `legal-docs-check` と `ai-conversion-rules-check` の観点も含める。
