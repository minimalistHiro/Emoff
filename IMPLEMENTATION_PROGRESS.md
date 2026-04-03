# 画面実装 進捗管理

> 最終更新: 2026-04-03

---

## このファイルの目的

設計完了済みの画面を順番に実装していくための進捗管理ファイル。
新しいスレッドを開始するたびにこのファイルを読み込み、「次はどこから実装するか」を判断する起点とする。

---

## 運用フロー

```
1. 新しいスレッドを開始する
2. 「次に進めるべき実装は？」または「実装の進捗は？」と依頼する
   → implementation-navigator スキルが起動し、このファイルと関連ドキュメントを読み込む
3. 次に実装すべき画面と、事前に確認すべき事項の案内を受ける
4. 1画面ずつ実装し、動作確認を経て完了とする
5. 完了後、このファイルの該当行を更新し、設計書を plans/completed/ に移動する
```

---

## 参照ドキュメント

| ドキュメント | 役割 | いつ参照するか |
|---|---|---|
| `plans/in_progress/` | 設計書（未実装） | 実装対象画面の詳細設計を確認 |
| `plans/completed/` | 設計書（実装済み） | 実装完了した設計書の格納先 |
| `FIRESTORE.md` | データベース構造 | Firestoreのフィールド・クエリ仕様の確認 |
| `UI_UX.md` | デザインルール・共通コンポーネント | CustomButton, CustomDialog等のルール準拠 |
| `BUSINESS_MODEL.md` | 仕様・プラン制約 | Free/Pro/Businessの機能制限等 |
| `DESIGN_PROGRESS.md` | 設計進捗 | 新たに設計完了した画面がないか確認 |
| `REVIEW_ITEMS.md` | 未決定事項 | ブロッカーの有無確認 |

---

## 実装の前提ルール

- **設計書が `plans/in_progress/` に存在する画面のみ実装対象とする**
- 設計書がない画面は、先に design-navigator で設計を完了させる
- 実装時は設計書の仕様に忠実に従う。仕様変更が必要な場合はユーザーに確認する
- UI_UX.md のコンポーネントルール（CustomButton, CustomDialog, CustomTextField 等）を必ず遵守する
- 1回のスレッドで扱う画面は原則1画面とする（品質の維持）

---

## 実装進捗

### 凡例

- `[x] 完了（日付）` — 実装完了・設計書を `plans/completed/` に移動済み
- `[ ] 未着手` — 設計完了済み・未実装
- `[ ] 進行中` — 実装作業中（スレッドをまたぐ場合）
- `[!] ブロック中` — 未決定事項や技術的問題の解決待ち

---

### フェーズ0: 基盤構築

アプリの骨格となるインフラ部分。個別画面の実装前に完了させる。

| # | 項目 | 状態 | 前提・ブロッカー | 備考 |
|---|------|------|-----------------|------|
| 0-1 | Firebase初期設定（Auth, Firestore） | [x] 完了（2026-04-03） | なし | `firebase_core`, `firebase_auth`, `cloud_firestore` の導入・初期化 |
| 0-2 | 認証サービス（AuthService） | [x] 完了（2026-04-03） | 0-1が先 | ログイン・登録・ログアウト・パスワードリセットのロジック |
| 0-3 | ボトムナビゲーション（メインシェル） | [x] 完了（2026-04-03） | 0-1が先 | ホーム・トーク一覧・設定の3タブ構成 |
| 0-4 | 共通ウィジェット確認 | [x] 完了（2026-04-03） | なし | CustomButton, CustomDialog, CustomTextField, CustomAppBar, CustomLoadingIndicator の存在確認・不足分の作成 |

**フェーズ完了条件:** Firebaseが接続でき、認証処理が動作し、ボトムナビゲーションで3タブが切り替えられる状態

---

### フェーズ1: 認証フロー

ユーザーがアプリに入るための最初の画面群。

| # | 画面名 | 設計書 | 状態 | 前提・ブロッカー |
|---|--------|--------|------|-----------------|
| 1-1 | スプラッシュ画面 | `plans/in_progress/20260403_splash_screen_design.md` | [x] 完了（2026-04-03） | フェーズ0完了が前提 |
| 1-2 | ログイン画面 | `plans/in_progress/20260403_login_screen_design.md` | [x] 完了（2026-04-03） | フェーズ0完了が前提 |
| 1-3 | 新規登録画面 + AI処理同意ポップアップ + オンボーディング画面 | `plans/in_progress/20260403_registration_screen_design.md` | [x] 完了（2026-04-03） | フェーズ0完了が前提 |
| 1-4 | パスワードリセット画面 | `plans/completed/20260403_password_reset_screen_design.md` | [x] 完了（2026-04-03） | フェーズ0完了が前提 |

**フェーズ完了条件:** 認証フロー全画面の実装が完了し、ログイン→ホーム画面への遷移が動作すること

---

### フェーズ2: メイン画面（ボトムナビゲーション直下）

認証後にユーザーが最初に触れる3つのタブ画面。

| # | 画面名 | 設計書 | 状態 | 前提・ブロッカー |
|---|--------|--------|------|-----------------|
| 2-1 | ホーム画面（友達一覧） | `plans/in_progress/20260403_home_friends_screen_design.md` | [x] 完了（2026-04-03） | フェーズ1完了が前提 |
| 2-2 | トーク一覧画面 | `plans/in_progress/20260403_talk_list_screen_design.md` | [x] 完了（2026-04-03） | フェーズ1完了が前提 |
| 2-3 | 設定画面 | `plans/in_progress/20260403_settings_screen_design.md` | [ ] 未着手 | フェーズ1完了が前提 |

**フェーズ完了条件:** 3タブすべてが設計書通りに実装され、画面間の遷移が正常に動作すること

---

### フェーズ3: コア機能画面

メイン画面からの遷移先。Emoffの中核機能を実装する。

| # | 画面名 | 設計書 | 状態 | 前提・ブロッカー |
|---|--------|--------|------|-----------------|
| 3-1 | トークルーム画面 | `plans/in_progress/20260403_talk_room_screen_design.md` | [ ] 未着手 | フェーズ2（トーク一覧画面）完了が前提。追加設計書: 通報フロー(`20260403_talk_room_report_flow_design.md`)、Free上限(`20260403_talk_room_free_limit_design.md`)、トーン選択(`20260403_talk_room_tone_selector_design.md`)、ブロック(`20260403_talk_room_block_dialog_design.md`) |

| 3-2 | 友達申請画面 | `plans/in_progress/20260403_friend_request_screen_design.md` | [ ] 未着手 | フェーズ2（ホーム画面）完了が前提 |

| 3-3 | 友達申請管理画面 | `plans/in_progress/20260403_friend_request_management_screen_design.md` | [ ] 未着手 | フェーズ2（ホーム画面）完了が前提 |

| 3-4 | 友達プロフィール画面 + ブロック確認ダイアログ | `plans/in_progress/20260403_friend_profile_screen_design.md` | [ ] 未着手 | フェーズ2（ホーム画面）完了が前提 |

| 3-5 | グループ作成画面 | `plans/in_progress/20260403_group_creation_screen_design.md` | [ ] 未着手 | フェーズ2（トーク一覧画面）完了が前提 |

| 3-6 | グループ管理画面 | `plans/in_progress/20260403_group_management_screen_design.md` | [ ] 未着手 | 3-5（グループ作成画面）完了が前提 |

**フェーズ完了条件:** メイン画面から遷移できる全画面が実装され、AI変換フローが動作すること

---

### フェーズ4: 設定サブ画面・その他

設定画面からの遷移先、共通コンポーネント、独立画面。

| # | 画面名 | 設計書 | 状態 | 前提・ブロッカー |
|---|--------|--------|------|-----------------|
| 4-1 | プロフィール設定画面 | `plans/in_progress/20260403_profile_settings_screen_design.md` | [ ] 未着手 | フェーズ2（設定画面）完了が前提 |
| 4-2 | アカウント設定画面 | `plans/in_progress/20260403_account_settings_screen_design.md` | [ ] 未着手 | フェーズ2（設定画面）完了が前提 |
| 4-3 | 通知設定画面 | `plans/in_progress/20260403_notification_settings_screen_design.md` | [ ] 未着手 | フェーズ2（設定画面）完了が前提 |
| 4-4 | お知らせ画面 | `plans/in_progress/20260403_announcements_screen_design.md` | [ ] 未着手 | フェーズ2（設定画面）完了が前提 |
| 4-5 | プライバシーポリシー画面 | `plans/in_progress/20260403_privacy_policy_screen_design.md` | [ ] 未着手 | フェーズ2（設定画面）完了が前提 |
| 4-6 | 利用規約画面 | `plans/in_progress/20260403_terms_of_service_screen_design.md` | [ ] 未着手 | フェーズ2（設定画面）完了が前提 |

| 4-7 | サイドドロワー | `plans/in_progress/20260403_side_drawer_design.md` | [ ] 未着手 | フェーズ2（ホーム画面・トーク一覧画面）完了が前提。共通ウィジェット `custom_drawer.dart` として実装 |

| 4-8 | サブスクリプション/課金画面 | `plans/in_progress/20260403_subscription_screen_design.md` | [ ] 未着手 | サイドドロワー・トークルームFree上限・グループ作成画面からの遷移先。アプリ内課金（StoreKit 2 / Google Play Billing）の実装が必要 |

**全画面の設計が完了。これ以上の追加はなし。**

---

## サマリー

| フェーズ | 項目数 | 完了 | 残り |
|---------|-------|------|------|
| 0. 基盤構築 | 4 | 4 | 0 |
| 1. 認証フロー | 4 | 4 | 0 |
| 2. メイン画面 | 3 | 2 | 1 |
| 3. コア機能画面 | 6 | 0 | 6 |
| 4. 設定サブ画面・その他 | 8 | 0 | 8 |
| **合計** | **25** | **10** | **15** |

※ 設計が完了するたびに項目が追加される

---

## 実装ログ

完了した画面の実装記録。いつ・何を実装したかの履歴を残す。

| 日付 | 画面/項目 | 備考 |
|------|----------|------|
| 2026-04-03 | 0-1 Firebase初期設定 | firebase_core/auth/firestore導入、Firebase.initializeApp()設定、flutterfire configure完了 |
| 2026-04-03 | 0-2 認証サービス | lib/services/auth_service.dart 作成。signUp/signIn/signOut/sendPasswordResetEmail/isUserIdAvailable |
| 2026-04-03 | 0-3 ボトムナビゲーション | lib/screens/main_shell.dart 作成。ホーム・トーク・設定の3タブ。main.dartで認証状態による画面分岐 |
| 2026-04-03 | 0-4 共通ウィジェット | CustomButton/CustomDialog/CustomDialogHelper/CustomTextField/CustomAppBar/CustomLoadingIndicator を全て新規作成 |
| 2026-04-03 | 1-1 スプラッシュ画面 | lib/screens/splash_screen.dart 作成。FadeIn+ScaleUpアニメーション、アンビエントグロー、最低1.5秒表示、認証状態で遷移分岐。main.dartのStreamBuilderを置き換え |
| 2026-04-03 | 1-2 ログイン画面 | lib/screens/login_screen.dart 作成。EMOFFブランディング、Welcome Backヘッダー、メール+パスワード入力、Firebase Auth認証、エラー時CustomDialog表示、アンビエントグロー（シアン+パープル）。CustomButtonにicon/heightパラメータ追加。splash_screen.dartのプレースホルダーを置き換え。ios/Podfileのplatformを15.0に設定 |
| 2026-04-03 | 1-3 新規登録画面 + AI処理同意 + オンボーディング | lib/screens/registration_screen.dart 作成（名前+メール+パスワード+確認+利用規約同意チェック、AI処理同意ポップアップ内蔵）。lib/screens/onboarding_screen.dart 作成（PageView 3スライド、ページインジケーター、スキップ機能）。auth_service.dart の signUp() から userId 必須を解除。login_screen.dart に新規登録画面への遷移を追加 |
| 2026-04-03 | 1-4 パスワードリセット画面 | lib/screens/password_reset_screen.dart 作成。メールアドレス入力+送信ボタンのシンプル構成。送信完了ダイアログ付き。login_screen.dart の _navigateToPasswordReset() を実装。**フェーズ1（認証フロー）全画面の実装完了** |
| 2026-04-03 | 2-1 ホーム画面（友達一覧） | lib/screens/home_screen.dart 作成。Circle of Clarityヒーローセクション、検索バー（カプセル型）、友達カードリスト（グレースケール→カラーアバターアニメ）、招待セクション（破線ボーダーCustomPainter）、FAB。StreamBuilderでusers/{uid}/friendsをリアルタイム監視。main_shell.dartのプレースホルダーを置き換え、ボトムナビを設計スペック準拠に更新 |
| 2026-04-03 | 2-2 トーク一覧画面 | lib/screens/talk_list_screen.dart 作成。AppBar（ハンバーガーメニュー+EMOFFタイトル+検索+プロフィールアバター）、COMMUNICATION HUBセクションヘッダー+New Discussionボタン、トークリスト（StreamBuilderでchats.where(members,arrayContains)をリアルタイム監視）、ChatItem（StatefulWidget: 1対1は相手ユーザー情報を非同期取得、グループはMaterial Iconアバター）、未読判定（lastMessageAt vs lastReadAt）、日時フォーマット（今日/Yesterday/曜日/月日）、グレースケール20%アバター、AI Concierge Readyセクション（破線ボーダー）。main_shell.dartのプレースホルダーを置き換え |
