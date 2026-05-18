---
name: github-commit-push-rules
description: emoffプロジェクトで「GitHubにコミットしてプッシュして」などの依頼が来たときに適用するGit操作ルール。コミット・プッシュ・mainマージ・ブランチ運用の手順を厳守する。
---

# GitHub Commit Push Rules

## 概要

emoffの変更をGitHub（https://github.com/minimalistHiro/Emoff.git）へコミット・プッシュする際の必須手順を適用する。

## 手順

ユーザーから「GitHubにコミットしてプッシュして」と依頼されたら、必ず以下の手順を順守する。

1. `/Users/kanekohiroki/Desktop/emoff` で `git status -sb` を確認する。
2. 変更がない場合は「変更なし」と報告して終了する。
3. 変更がある場合は以下を順に実行する。
4. `.gitignore`に含まれているもの以外は全てステージングする。
5. 現在のブランチにコミットしてプッシュする。
6. その後、`main`にマージして`main`へpushする。
7. マージ後は元のブランチに戻す。
8. 元のブランチへ戻した時、そのブランチ名が今日の日付（`YYYY-mm-dd`）でない場合は、新しいブランチを`YYYY-mm-dd`形式で作成して切り替える。
9. コミットメッセージは任意。

## 注意事項

- 依頼があるまで勝手にコミット・プッシュを行わない。
- 既存の未コミット変更がある場合は、内容を確認してから手順を進める。
