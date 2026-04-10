# TODO リスト

> 作成日: 2026-04-01

---

## ルール

- 各項目には以下を記載する:
  - **優先度**: 最高 / 高 / 中 / 低（長期）のいずれか
  - **内容**: 実装・対応内容の概要
  - **状態**: `[ ] 未着手` / `[ ] 計画済み（日付）` / `[ ] 進行中` / `[x] 完了（日付）` / `[x] 廃止（日付）`
- 完了・廃止になった項目は COMPLETED.md に移動する。
- **IDの再利用は禁止**。TODO.md と COMPLETED.md の両方を確認し、既存の最大番号の次を使用すること。

---

## タスク一覧

<!-- 例: | A-1 | 高 | チャット画面の実装 | [ ] 未着手 | -->

| ID | 優先度 | 内容 | 状態 |
|---|---|---|---|
| A-13 | 高 | 通報機能の実装（reportsコレクション、通報理由選択UI） | [ ] 未着手 |
| A-24 | 中 | グループアイコンの画像選択・アップロード機能実装（group_management_screen.dartの画像選択ボトムシートTODOを実装） | [ ] 未着手 |
| A-25 | 高 | RevenueCatダッシュボード設定（APIキー取得、App Store Connect / Google Play Console連携、Entitlement `pro` + Offering作成、商品ID `emoff_pro_monthly` 登録） | [ ] 未着手 |
| A-26 | 高 | App Store Connect / Google Play ConsoleでのサブスクリプションProduct登録（`emoff_pro_monthly` ¥300/月 自動更新型） | [ ] 未着手 |
| A-27 | 中 | RevenueCat Webhook受信用Cloud Functions実装（Webhook → Firestore `users/{uid}.plan` / `planExpiresAt` 更新） | [ ] 未着手 |
