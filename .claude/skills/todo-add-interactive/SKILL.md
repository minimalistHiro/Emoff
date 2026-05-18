---
name: todo-add-interactive
description: emoffプロジェクトで複数要望や曖昧な依頼をTODOへ追加する前に、関連ドキュメントを読み込み、重複確認と論点整理を行う。「TODOに追加して」「以下をタスク化して」「要望をTODOに入れて」等の依頼が対象。
---

# TODO Add Interactive

## 手順

1. `TODO.md`、`COMPLETED.md`、`REVIEW_ITEMS.md` を確認する。
2. UI/UX、画面、Firestore、ビジネス、法務に関係する場合は該当MDも読む。
3. 既存タスク・完了済みタスク・要検討事項との重複を確認する。
4. 未確定の論点は `REVIEW_ITEMS.md`、実装可能な作業は `TODO.md` に分類する。
5. 不明点が実装可否に影響する場合だけユーザーへ確認する。

## 注意事項

- 依頼文をそのままTODO化せず、Emoffの仕様に合わせて実装単位へ分割する。
- IDは再利用しない。
