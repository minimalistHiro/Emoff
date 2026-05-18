---
name: autonomous-todo-batch
description: emoffプロジェクトでTODO.mdから指定キーワードに該当する未着手項目を抽出し、計画書作成→専用ブランチ作成→Phase順の実装→解析・テスト→TODO/COMPLETED/QA更新までを一括で進める。「To Doをすべてバッチで進めて」「TODOをバッチで進めて」「課金関連のTODOを一括で実装して」「バグ修正をバッチで進めて」等の依頼が対象。
---

# Autonomous TODO Batch

## 概要

ユーザーが指定した自由形式のキーワード（例: 「すべて」「課金関連」「バグ修正」「UI」）に該当する未着手TODOを `/Users/kanekohiroki/Desktop/emoff/TODO.md` から抽出し、計画書を作成して承認を得たうえで、複数Phaseの実装を自律的に進める。

Phase A（準備）で対象範囲・計画・ブランチを確定し、Phase A の最後でユーザー承認を1回だけ求める。承認後の Phase B（実装）は、重大な仕様未決定・解析不能エラー・テスト不能エラーが出ない限り、ユーザー確認を挟まずに完了まで進める。

push と main マージは行わない。完了後にユーザーが `github-commit-push-rules` を呼ぶ。

---

## Phase A: 準備

### A-1. キーワード解釈と対象抽出

1. ユーザー依頼から対象キーワードを取得する。
   - 「すべて」「全部」「全件」の場合は、`TODO.md` の `[ ] 未着手` をすべて対象候補にする。
   - キーワードが空、または対象が特定できない場合のみ、対象キーワードをユーザーに確認する。
2. `/Users/kanekohiroki/Desktop/emoff/TODO.md` を読み込む。
3. 状態が `[ ] 未着手` の項目から、キーワードに該当するものを抽出する。判断材料:
   - ID
   - 優先度
   - 内容
   - 備考列がある場合は備考
4. 抽出結果を提示する。

```markdown
「{キーワード}」に該当するTODOを以下{N}件と判断しました。

| ID | 優先度 | 内容 |
|---|---|---|
| ... | ... | ... |
```

5. ユーザーに「この範囲で進めてよいですか。除外・追加したい項目があれば教えてください」と確認する。
6. 応答に基づいて対象を調整する。

### A-2. 仕様ファイルの事前読込

実装前に、対象TODOに関係する仕様ファイルを必ず読む。

- 画面構成・画面遷移: `APP_SCREENS.md` / `SCREEN_DESIGN.md`
- UI/UX変更: `UI_UX.md`
- Firestore・セキュリティルール変更: `FIRESTORE.md`
- ビジネスモデル・収益モデル・KPI・課金: `BUSINESS_MODEL.md`
- 未決定事項・要検討事項: `REVIEW_ITEMS.md`
- 完了・未着手管理: `TODO.md` / `COMPLETED.md`
- QA運用: `QA_CHECKLIST.md` / `QA_RESULTS.md` / `qa/`（存在する場合）

UIやUXに関わる作業では、必ず `UI_UX.md` を読んでからコードを変更する。

### A-3. Phase構成

抽出したTODOを依存関係と変更範囲でPhaseに分ける。

- Firestore・Cloud Functions・課金設定など、基盤になる変更を先に置く。
- 同じ画面・Provider・Repository・Cloud Functions に触れる項目は同一Phaseにまとめる。
- UIだけで完結する軽微な変更は、依存関係がなければ後段Phaseにまとめる。
- 仕様未決定で実装判断が危険な項目は対象から外し、`REVIEW_ITEMS.md` への追加候補として扱う。

各Phaseには以下を定義する。

- Phase番号
- 対象TODO ID
- 想定影響ファイル
- 実装方針
- 検証方針（`flutter analyze` 必須、`flutter test` は対象がある場合）

### A-4. 計画書作成

`plans/in_progress/{YYYYMMDD}_batch_{topic_slug}.md` を作成する。

```markdown
# バッチ実行計画書: {キーワード}

- 作成日: {YYYY-MM-DD}
- ステータス: 未開始
- 対象TODO: {N}件
- 専用ブランチ: batch-{topic_slug}-{YYYYMMDD}

## 対象TODO一覧

| ID | 優先度 | 内容 |
|---|---|---|
| ... | ... | ... |

## Phase構成

### Phase 1: {タイトル}
- 対象TODO: {ID}
- 想定影響ファイル: {パス}
- 実装方針: {概要}
- 検証: flutter analyze / flutter test（対象がある場合）
- 詳細計画書: plans/in_progress/{YYYYMMDD}_batch_{topic_slug}_phase1.md
- ステータス: 未着手

## 進捗ログ
```

### A-5. 専用ブランチ作成

1. `git status -sb` で現在ブランチと未コミット変更を確認する。
2. 未コミット変更がある場合は、ユーザーに「現在の変更を先に扱う必要がある」ことを伝え、続行可否を確認する。
3. `git fetch origin main` と `git log HEAD..origin/main --oneline` で main の未取込コミットを確認する。
   - 未取込コミットがある場合は、取り込むか確認する。
   - 取り込みを承認されたら `git merge origin/main` を実行する。
   - コンフリクトしたら停止して報告する。
4. `batch-{topic_slug}-{YYYYMMDD}` ブランチを作成する。
5. 既に同名ブランチがある場合は `-2`, `-3` のように連番を付ける。

### A-6. 最終承認

計画書とブランチを作成したら、以下を提示して最終承認を得る。

```markdown
以下の計画でバッチを開始します。

対象TODO: {N}件
Phase構成: {M}個
専用ブランチ: batch-{topic_slug}-{YYYYMMDD}
計画書: plans/in_progress/{file_name}

このまま自律実行を開始してよろしいですか？
```

承認されたら Phase B に進む。承認されない場合は、計画書とブランチを残して終了する。

---

## Phase B: 実装

### B-1. Phaseループ

各Phaseで以下を順に実行する。

#### B-1-a. 関連コード調査

対象TODOに関係する既存実装を調べる。

- 関連ファイル
- 関連する Provider / Repository / Service / Widget
- 既存の類似実装パターン
- 影響範囲と副作用

必要に応じてサブエージェントを使ってよい。ただし、同じ依存関係グループの実装は並列化しない。

#### B-1-b. Phase詳細計画書作成

`plans/in_progress/{YYYYMMDD}_batch_{topic_slug}_phase{N}.md` を作成する。

```markdown
# Phase {N} 詳細計画書: {タイトル}

- 親計画書: plans/in_progress/{YYYYMMDD}_batch_{topic_slug}.md
- 対象TODO: {ID}
- 作成日: {YYYY-MM-DD}
- ステータス: 未着手

## 1. 変更対象ファイル

| 種別 | パス | 概要 |
|---|---|---|
| 修正 | ... | ... |

## 2. 具体的な変更内容

## 3. 既存コードへの影響範囲

## 4. 回避すべき副作用

## 5. 検証手順

## 6. ドキュメント更新

| ドキュメント | 更新要否 | 更新内容 |
|---|---|---|
| APP_SCREENS.md | 要/不要 | ... |
| SCREEN_DESIGN.md | 要/不要 | ... |
| UI_UX.md | 要/不要 | ... |
| FIRESTORE.md | 要/不要 | ... |
| BUSINESS_MODEL.md | 要/不要 | ... |
| REVIEW_ITEMS.md | 要/不要 | ... |
| TODO.md / COMPLETED.md | 要 | 完了TODOの移動 |
| QA_CHECKLIST.md / qa/ | 要/不要 | ... |
```

詳細計画書を作成するたびにユーザー承認は求めない。

#### B-1-c. 実装

Phase詳細計画書に従って実装する。

- 詳細計画書の変更対象・方針から逸脱しない。
- 既存の命名・配置・状態管理パターンに合わせる。
- UI変更時は `UI_UX.md` と既存デザインに合わせる。
- Firestore変更時は `FIRESTORE.md` とセキュリティルールへの影響を確認する。
- 課金・プラン判定変更時は `BUSINESS_MODEL.md` の Free/Pro 境界を確認する。

設計判断が必要な未決定事項が出た場合は、実装を止めて B-4 に進む。

#### B-1-d. 解析

`flutter analyze` を実行する。

- エラー0: 次へ進む。
- error / warning あり: 自動修正を試みる。
- 同一エラーに対する修正試行は最大3回まで。
- 3回を超えたら B-4 に進む。

#### B-1-e. テスト

対象テストがある場合は `flutter test` を実行する。

- 全テスト成功: 次へ進む。
- 単一原因の失敗: 最大2回まで自動修正を試みる。
- 複数領域にまたがる失敗、インフラ起因で判断不能な失敗、修正不能な失敗は B-4 に進む。

#### B-1-f. ドキュメント更新

Phaseで完了したTODOについて、関連ドキュメントを更新する。

1. `TODO.md` から完了項目を削除する。
2. `COMPLETED.md` の今日の日付セクションに完了項目を追記する。
3. `qa/` ディレクトリが存在する場合は、現在バージョンの `qa/QA_Vx.x.x.md` にチェック項目を追加する。
4. `QA_CHECKLIST.md` が運用されている場合は必要に応じて更新する。
5. `APP_SCREENS.md` / `SCREEN_DESIGN.md` / `FIRESTORE.md` / `UI_UX.md` / `BUSINESS_MODEL.md` / `REVIEW_ITEMS.md` は、Phase詳細計画書の「ドキュメント更新」で要としたものだけ更新する。
6. テスト結果が確定している場合のみ `QA_RESULTS.md` に追記する。未実施なら追記しない。
7. Phase詳細計画書と全体計画書のステータスを更新する。

TODOの完了処理は `todo-complete` の運用に合わせる。

#### B-1-g. ローカルコミット

Phaseごとにローカルコミットする。pushはしない。

```text
Phase {N}: {Phaseタイトル} ({TODO IDs})
```

コミット前に `git status --short` を確認し、機密ファイル（`.env` / `GoogleService-Info.plist` 等）を含めない。`git add -A` は使わず、対象ファイルを明示してステージングする。

### B-2. コード整理

すべてのPhaseが完了したら、必要に応じて `code-cleanup` を実行する。

- 軽微な整理で済む場合のみ適用する。
- 仕様変更が必要な整理は行わない。
- 整理後に `flutter analyze` を再実行する。
- 修正が発生した場合は、ローカルコミットする。

### B-3. 最終確認

1. `git status -sb` で作業状態を確認する。
2. `flutter analyze` の最終結果を確認する。
3. 実行した `flutter test` の結果を整理する。
4. 全体計画書を `実装完了（YYYY-MM-DD）` に更新する。
5. 必要であれば `plans/in_progress/` から `plans/completed/` へ移動する。
6. 完了サマリーを出力する。

完了サマリーには以下を含める。

- 実装したTODO一覧
- Phaseごとのコミット
- 更新した主要ファイル
- 計画書パス
- 検証結果
- 次の推奨操作: `github-commit-push-rules`

### B-4. 重大エラー停止

以下の場合は自律実行を止める。

- 仕様未決定で実装判断が危険な場合
- `flutter analyze` の同一エラー修正が3回を超えた場合
- `flutter test` の修正が2回を超えた場合
- 複数領域にまたがる予期しない失敗が出た場合
- コンフリクトやブランチ状態異常で安全に続行できない場合

停止時は以下を行う。

1. 全体計画書に停止記録を追記する。

```markdown
## 停止記録

- 停止 Phase: Phase {N}
- 停止時刻: {YYYY-MM-DD HH:MM}
- エラー概要: {概要}
- 試行した修正: {内容}
- 推奨対応: {人間が確認すべき点}
```

2. ユーザーに停止理由、現在ブランチ、未コミット変更、次に確認すべき点を報告する。
3. ブランチと作業内容は残す。勝手に巻き戻さない。

---

## 対象となる依頼例

- To Do をすべてバッチで進めて
- TODOを全部バッチで進めて
- 課金関連のTODOを一括で実装して
- UI関連のTODOをバッチで進めて
- バグ修正をまとめて進めて
- A-25 と A-26 をバッチで進めて

---

## 注意事項

- 返答は必ず日本語で行う。
- Phase A の最後の承認以外は原則質問しない。
- 重大エラー時は止める。自己判断で危険な仕様決定をしない。
- push と main マージは行わない。
- UI/UX作業では必ず `UI_UX.md` を事前に読む。
- ドキュメント更新は AGENTS.md の参照ルールに従う。
- 完了TODOは `TODO.md` から削除し、`COMPLETED.md` へ移動する。
- QAチェックリストが存在する場合は、完了TODOに対応するチェック項目を追加する。
- `QA_RESULTS.md` はテスト結果が確定している場合だけ更新する。
- ユーザーの既存変更を勝手に戻さない。
