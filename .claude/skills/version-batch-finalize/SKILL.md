---
name: version-batch-finalize
description: emoffプロジェクトでversion-batchやautonomous-todo-batch後のブランチ統合、delta集約、TODO/COMPLETED/QA/仕様MD更新を行う。「バッチを最終化して」「クラスタを統合して」「全部マージして整理して」等の依頼が対象。
---

# Version Batch Finalize

## 手順

1. 各作業ブランチや `plans/in_progress/*_delta.md` を確認する。
2. `consolidate-deltas` でドキュメント更新内容を集約する。
3. TODO完了項目を `COMPLETED.md` に移動し、QA項目を追加する。
4. 必要な仕様MDを更新する。
5. テスト・解析を実行して結果を報告する。

## 注意事項

- ユーザーの未コミット変更は勝手に戻さない。
- マージやpushはユーザー依頼がある場合のみ行う。
