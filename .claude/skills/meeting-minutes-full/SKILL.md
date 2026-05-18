---
name: meeting-minutes-full
description: emoffプロジェクトで会議メモや議事録を整理し、TODO・REVIEW_ITEMS・仕様MDへの反映方針を作る。「議事録を整理して」「会議メモをまとめて」「打ち合わせ内容を反映して」等の依頼が対象。
---

# Meeting Minutes Full

## 手順

1. 会議メモを決定事項、未決定事項、実装タスク、メモに分類する。
2. `TODO.md`、`REVIEW_ITEMS.md`、`COMPLETED.md` と突合する。
3. 仕様変更がある場合は `BUSINESS_MODEL.md`、`APP_SCREENS.md`、`SCREEN_DESIGN.md`、`FIRESTORE.md`、`UI_UX.md` を確認する。
4. 必要に応じて `meeting_notes/YYYY-MM-DD.md` として保存する。
5. ユーザー承認後にTODO・REVIEW・仕様MDへ反映する。

## 注意事項

- 決定事項と検討事項を混ぜない。
- スプレッドシート同期が必要なら `sync-all-to-sheets` を後続で実行する。
