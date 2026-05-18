---
name: github-batch-commit
description: emoffプロジェクトでバッチ実装中の中間コミットを行う内部運用スキル。pushやmainマージは行わず、関連ドキュメント更新チェック後にコミットする。
---

# GitHub Batch Commit

## 手順

1. `git status -sb` を確認する。
2. 変更範囲に対応する仕様MD、TODO、QAの更新漏れがないか確認する。
3. ユーザーがコミットを依頼している場合のみステージング・コミットする。

## 注意事項

- pushとmainマージは行わない。
- 通常のGitHub公開依頼では `github-commit-push-rules` を使う。
