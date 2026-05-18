---
name: version-batch
description: emoffプロジェクトでTODO.mdの未着手項目を依存関係ごとにクラスタ化し、1バージョン分の実装計画と作業をまとめて進める。「TODOを全部バッチで進めて」「未着手TODOを一気に実装して」等の依頼が対象。
---

# Version Batch

## 手順

1. `TODO.md`、`COMPLETED.md`、`REVIEW_ITEMS.md` を読む。
2. 関連するTODOをクラスタに分ける。
3. `plans/in_progress/` にバッチ計画を作る。
4. ユーザーが明示的にサブエージェント利用を承認している場合のみ、クラスタ単位で分担する。
5. 実装後は `version-batch-finalize` で統合する。

## 注意事項

- 仕様未決定のものは実装せず `REVIEW_ITEMS.md` に残す。
- UI変更時は `UI_UX.md` を必ず確認する。
