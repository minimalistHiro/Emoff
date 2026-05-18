---
name: firestore-schema-check
description: emoffプロジェクトでFirestoreスキーマ、セキュリティルール、Cloud Functions、実装コードとの整合を確認する。「Firestore設計を確認して」「ルールと実装の整合を見て」「スキーマを確認して」等の依頼が対象。
---

# Firestore Schema Check

## 参照ファイル

- `FIRESTORE.md`
- `firestore.rules`
- `firestore.indexes.json`
- `functions/`
- `lib/`

## 手順

1. `FIRESTORE.md` で想定コレクション・フィールドを確認する。
2. 実装コードの読み書きパスを検索する。
3. セキュリティルールとインデックス要件を確認する。
4. 不一致があれば、仕様MD・実装・ルールのどれを直すべきか分けて提示する。

## 注意事項

- Firestoreに関する変更では `FIRESTORE.md` の更新漏れを残さない。
