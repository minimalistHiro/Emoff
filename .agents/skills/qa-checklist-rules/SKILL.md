---
name: qa-checklist-rules
description: emoffプロジェクトのQAチェックリスト、qa/QA_V*.md、QA_RESULTS.md、GoogleスプレッドシートQAタブの共通ルールを定義する。QA作成・同期・CSV取込・Fail確認の前に参照する。
---

# QA Checklist Rules

## 基本形式

- バージョン別チェックリストは `qa/QA_Vx.x.x.md` に置く。
- 結果は `QA_RESULTS.md` に追記する。
- スプレッドシート列は `テストID / セクション / 区分 / 共有 / テスト内容 / 担当者 / 結果 / 実施日 / メモ` とする。

## マークダウン項目形式

```markdown
- [ ] `V100-001` [バグ修正][由来:独自][共有:-] テスト内容
```

## 共有列

- `〇`: 共有する
- `×`: 共有しない
- `-`: 未判定
- AIが自動で `〇` / `×` を決めない。初期値は `-`。

## 注意事項

- TODO完了時は、必要なQA項目を該当バージョンの `qa/QA_Vx.x.x.md` に追加する。
- Fail項目からTODOを作る場合は `todo-add-interactive` を使い、重複確認する。
