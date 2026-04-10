# 画面実装 進捗管理

> 最終更新: 2026-04-09

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
| `plans/completed/` | 設計書（全画面実装完了） | 設計書の格納先 |
| `FIRESTORE.md` | データベース構造 | Firestoreのフィールド・クエリ仕様の確認 |
| `UI_UX.md` | デザインルール・共通コンポーネント | CustomButton, CustomDialog等のルール準拠 |
| `BUSINESS_MODEL.md` | 仕様・プラン制約 | Free/Pro/Businessの機能制限等 |
| `DESIGN_PROGRESS.md` | 設計進捗 | 新たに設計完了した画面がないか確認 |
| `REVIEW_ITEMS.md` | 未決定事項 | ブロッカーの有無確認 |

---

## 実装の前提ルール

- **設計書が `plans/completed/` に存在する画面のみ実装対象とする**
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
| 1-1 | スプラッシュ画面 | `plans/completed/20260403_splash_screen_design.md` | [x] 完了（2026-04-03） | フェーズ0完了が前提 |
| 1-2 | ログイン画面 | `plans/completed/20260403_login_screen_design.md` | [x] 完了（2026-04-03） | フェーズ0完了が前提 |
| 1-3 | 新規登録画面 + AI処理同意ポップアップ + オンボーディング画面 | `plans/completed/20260403_registration_screen_design.md` | [x] 完了（2026-04-03） | フェーズ0完了が前提 |
| 1-4 | パスワードリセット画面 | `plans/completed/20260403_password_reset_screen_design.md` | [x] 完了（2026-04-03） | フェーズ0完了が前提 |

**フェーズ完了条件:** 認証フロー全画面の実装が完了し、ログイン→ホーム画面への遷移が動作すること

---

### フェーズ2: メイン画面（ボトムナビゲーション直下）

認証後にユーザーが最初に触れる3つのタブ画面。

| # | 画面名 | 設計書 | 状態 | 前提・ブロッカー |
|---|--------|--------|------|-----------------|
| 2-1 | ホーム画面（友達一覧） | `plans/completed/20260403_home_friends_screen_design.md` | [x] 完了（2026-04-03） | フェーズ1完了が前提 |
| 2-2 | トーク一覧画面 | `plans/completed/20260403_talk_list_screen_design.md` | [x] 完了（2026-04-03） | フェーズ1完了が前提 |
| 2-3 | 設定画面 | `plans/completed/20260403_settings_screen_design.md` | [x] 完了（2026-04-03） | フェーズ1完了が前提 |

**フェーズ完了条件:** 3タブすべてが設計書通りに実装され、画面間の遷移が正常に動作すること

---

### フェーズ3: コア機能画面

メイン画面からの遷移先。Emoffの中核機能を実装する。

| # | 画面名 | 設計書 | 状態 | 前提・ブロッカー |
|---|--------|--------|------|-----------------|
| 3-1 | トークルーム画面 | `plans/completed/20260403_talk_room_screen_design.md` | [x] 完了（2026-04-03） | 全機能実装完了: 基本UI + AI変換プレビュートレイ + オプションメニュー + 通報フロー + ブロック確認ダイアログ + Free上限到達UI + トーン選択UI + トーク内検索 |

| 3-2 | 友達申請画面 | `plans/completed/20260403_friend_request_screen_design.md` | [x] 完了（2026-04-04） | フェーズ2（ホーム画面）完了が前提 |

| 3-3 | 友達申請管理画面 | `plans/completed/20260403_friend_request_management_screen_design.md` | [x] 完了（2026-04-04） | フェーズ2（ホーム画面）完了が前提 |

| 3-4 | 友達プロフィール画面 + ブロック確認ダイアログ | `plans/completed/20260403_friend_profile_screen_design.md` | [x] 完了（2026-04-04） | フェーズ2（ホーム画面）完了が前提 |

| 3-5 | グループ作成画面 | `plans/completed/20260403_group_creation_screen_design.md` | [x] 完了（2026-04-04） | フェーズ2（トーク一覧画面）完了が前提 |

| 3-6 | グループ管理画面 | `plans/completed/20260403_group_management_screen_design.md` | [x] 完了（2026-04-05） | 3-5（グループ作成画面）完了が前提 |

**フェーズ完了条件:** メイン画面から遷移できる全画面が実装され、AI変換フローが動作すること

---

### フェーズ4: 設定サブ画面・その他

設定画面からの遷移先、共通コンポーネント、独立画面。

| # | 画面名 | 設計書 | 状態 | 前提・ブロッカー |
|---|--------|--------|------|-----------------|
| 4-1 | プロフィール設定画面 | `plans/completed/20260403_profile_settings_screen_design.md` | [x] 完了（2026-04-05） | フェーズ2（設定画面）完了が前提 |
| 4-2 | アカウント設定画面 | `plans/completed/20260403_account_settings_screen_design.md` | [x] 完了（2026-04-08） | フェーズ2（設定画面）完了が前提 |
| 4-3 | 通知設定画面 | `plans/completed/20260403_notification_settings_screen_design.md` | [x] 完了（2026-04-08） | フェーズ2（設定画面）完了が前提 |
| 4-4 | お知らせ画面 | `plans/completed/20260403_announcements_screen_design.md` | [x] 完了（2026-04-08） | フェーズ2（設定画面）完了が前提 |
| 4-5 | プライバシーポリシー画面 | `plans/completed/20260403_privacy_policy_screen_design.md` | [x] 完了（2026-04-08） | フェーズ2（設定画面）完了が前提 |
| 4-6 | 利用規約画面 | `plans/completed/20260403_terms_of_service_screen_design.md` | [x] 完了（2026-04-08） | フェーズ2（設定画面）完了が前提 |

| 4-7 | サイドドロワー | `plans/completed/20260403_side_drawer_design.md` | [x] 完了（2026-04-09） | フェーズ2（ホーム画面・トーク一覧画面）完了が前提。共通ウィジェット `custom_drawer.dart` として実装 |

| 4-8 | サブスクリプション/課金画面 | `plans/completed/20260403_subscription_screen_design.md` | [x] 完了（2026-04-09） | RevenueCat SDK統合。サイドドロワー×2・トークルームFree上限×2・グループ作成ダイアログからの遷移接続完了 |

**全画面の設計が完了。これ以上の追加はなし。**

---

## サマリー

| フェーズ | 項目数 | 完了 | 残り |
|---------|-------|------|------|
| 0. 基盤構築 | 4 | 4 | 0 |
| 1. 認証フロー | 4 | 4 | 0 |
| 2. メイン画面 | 3 | 3 | 0 |
| 3. コア機能画面 | 6 | 6 | 0 |
| 4. 設定サブ画面・その他 | 8 | 8 | 0 |
| **合計** | **25** | **25** | **0** |

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
| 2026-04-03 | 2-3 設定画面 | lib/screens/settings_screen.dart 作成。プロフィールサマリー（StreamBuilderでusers/{uid}をリアルタイム監視、アバター96px+ユーザー名+メール+Edit Profileボタン）、CONFIGURATIONセクション（Notifications/Account Settings/Announcements）、LEGAL & PRIVACYセクション（Privacy Policy/Terms of Service）、ログアウトボタン（danger、確認ダイアログ付き→AuthService.signOut()→ログイン画面遷移）、バージョン情報。main_shell.dartの_PlaceholderScreenを置き換え・削除。**フェーズ2（メイン画面）全画面の実装完了** |
| 2026-04-03 | 3-1 トークルーム画面（基本UI） | lib/screens/talk_room_screen.dart 作成。lib/services/chat_service.dart 作成。AppBar（戻る+相手名+肩書き+検索+メニュー）、メッセージキャンバス（StreamBuilderでchats/{chatId}/messagesリアルタイム監視、日付インジケーター、送受信バブル、NEUTRALIZEDバッジ）、インプットドック（テキスト入力+CONFIRMボタン）。talk_list_screen.dartからの遷移を接続 |
| 2026-04-03 | 3-1 トークルーム画面（全機能） | AI変換プレビュートレイ（CONFIRM→スライドアップトレイ、Original/Emoff-ed 2カラム比較、SEND NEUTRALIZED/REFINE AIボタン、MVPはモック変換）。オプションメニュー（通報/ブロック/グループ管理）。通報フロー（メニューからのユーザー通報+メッセージ長押しからのメッセージ通報、理由4択+補足入力、Firestore reports保存）。ブロック確認ダイアログ（3ステップ確認、blocked_usersサブコレクション保存、成功時トーク一覧へ戻る）。Free上限到達UI（残数カウンター常時表示、残り5通警告バナー、上限到達ダイアログ、インプットドックロック、SharedPreferences管理）。トーン選択UI（4トーン、チャットごとにSharedPreferences保存、Pro以上のみチップ表示、バッジ/プレビューヘッダー連動）。トーク内検索（検索モードAppBar、クライアントサイドフィルター）。**フェーズ3-1完了** |
| 2026-04-04 | 3-2 友達申請画面 | lib/screens/friend_request_screen.dart 作成。@プレフィックス付きCustomTextField+円形検索ボタン、検索結果4状態切り替え（初期/検索中/発見/未発見）、ボタン5パターン分岐（申請可能/友達済み/申請済み/申請受信中/自分自身）、ブロック中ユーザーは未発見表示、確認ダイアログ→申請送信→成功ダイアログ、自分のID表示+クリップボードコピー。CustomTextFieldにprefixIconパラメータ追加。home_screen.dartの3箇所（person_add/Invite Friend/FAB）に遷移接続 |
| 2026-04-04 | 3-3 友達申請管理画面 | lib/screens/friend_request_management_screen.dart 作成。AppBar「REQUESTS」+シアンバッジ、セクションヘッダー（件数表示）、申請カード（アバター+名前+@userId+相対日時+承認/拒否ボタン）、承認:確認ダイアログ→バッチ書き込み（status更新+双方friends作成）→成功ダイアログ、拒否:確認ダイアログ→静かにカード消失、空状態、二重タップ防止、userIdキャッシュ。home_screen.dart・friend_request_screen.dartからの遷移接続済み |
| 2026-04-04 | 3-4 友達プロフィール画面 + ブロック確認ダイアログ | lib/screens/friend_profile_screen.dart 作成。透過AppBar（ドロップシャドウ付きアイコン）+ポップアップメニュー（ブロック/通報）、背景画像240px（未設定時グラデーション）+グラデーションオーバーレイ、プロフィールアイコン96px（白ボーダー、背景に重なる配置）、ユーザー名+@userId+自己紹介文（任意表示）、トークボタン下部固定（既存chatId利用 or 新規チャット作成+chatId書き戻し）、ブロック確認ダイアログ（blockアイコン+箇条書き3点+キャンセル/ブロック横並び→blocked_users作成+friends双方削除→ホーム画面に戻る）。home_screen.dartの友達カードタップに遷移接続 |
| 2026-04-04 | 3-5 グループ作成画面 | lib/screens/group_creation_screen.dart 作成。Freeプランユーザー向けアップグレード促進ダイアログ（CustomDialog: groupsアイコン+説明+プランを見る/あとでボタン）、AppBar「New Group」+右端「Create」テキストボタン（有効/無効）、グループ情報セクション（80pxアイコン+カメラオーバーレイ+グループ名入力50文字上限カウンター付き）、選択済みメンバープレビュー（横スクロールチップリスト: アバター+名前+削除×ボタン）、友達検索バー（カプセル型リアルタイムフィルタリング）、友達リスト（StreamBuilder+チェック式選択/解除、グレースケール→カラーアバター、@userId表示）、固定フッター（メンバー数+作成ボタン）、破棄確認ダイアログ、グループ作成→Firestore chats(type:group)→トークルーム画面pushReplacement遷移、Empty State+友達申請画面遷移。talk_list_screen.dartのNew Discussionボタンにプラン判定+遷移接続 |
| 2026-04-05 | 4-1 プロフィール設定画面 | lib/screens/profile_settings_screen.dart 作成。CustomAppBar「Edit Profile」、背景画像エリア200px（半透明オーバーレイ+カメラアイコン、タップで画像選択ボトムシート）、プロフィールアイコン96px（白ボーダー+シアンカメラバッジ、背景に重なる配置）、入力フォーム（Name 20文字/User ID 20文字@プレフィックス+半角英数字制限+自動小文字変換+一意性チェック/Bio 150文字 minLines:2 maxLines:4）、文字数カウンター各フィールド、Saveボタン（変更なし/バリデーションエラー時非活性）、画像選択ボトムシート（カメラ/ライブラリ/削除、image_picker+image_cropper、アイコン1:1/背景16:9アスペクト比固定クロップ）、Firebase Storageアップロード（users/{uid}/icon.jpg, background.jpg）、AI変換プレビューダイアログ（変換前/後比較、やり直す/確認ボタン、MVPモック変換）、破棄確認ダイアログ（PopScope連動）、保存処理（画像アップロード→Firestore更新→完了ダイアログ→設定画面に戻る）。CustomTextFieldにminLines/focusNode/inputFormattersパラメータ追加。settings_screen.dartのEdit Profileボタンに遷移接続。iOS Info.plistにカメラ・フォトライブラリ権限追加。pubspec.yamlにfirebase_storage/image_picker/image_cropper追加 |
| 2026-04-08 | 4-2 アカウント設定画面 | lib/screens/account_settings_screen.dart 作成。ACCOUNTセクション（Email Address: 現在メール表示+変更ダイアログ、Password: 変更ダイアログ）、DANGER ZONEセクション（Logout: アイコン付き確認ダイアログ+signOut+ログイン画面遷移、Delete Account: 2段階確認フロー 警告ダイアログ→パスワード再入力→再認証→usersドキュメント削除+Auth削除+ログイン画面遷移）。全ダイアログで再認証（reauthenticateWithCredential）、ローディング表示、toUserFriendlyErrorエラー変換。Cloud Functionsによる関連データクリーンアップはTODO。settings_screen.dartのAccount Settingsに遷移接続 |
| 2026-04-08 | 4-4 お知らせ画面 | lib/screens/announcements_screen.dart 作成。CustomAppBar「Announcements」、お知らせカード（#1A1A1A背景、角丸12px、タイトル+日付「YYYY年M月D日」形式+本文最大3行ellipsis）、展開/折りたたみ（AnimatedSize、「もっと見る」/「閉じる」切替）、ワンショット取得（announcements.orderBy createdAt desc .get()）、RefreshIndicatorでプルトゥリフレッシュ、空状態（notifications_noneアイコン+テキスト）、CustomLoadingIndicator、エラー時showCustomDialog。settings_screen.dartのAnnouncementsにAnnouncementsScreen遷移接続 |
| 2026-04-08 | 4-3 通知設定画面 | lib/screens/notification_settings_screen.dart 作成。CustomAppBar「Notifications」、メイントグル（Push Notifications: 全通知一括ON/OFF、OFF時は個別設定をopacity 0.4で非活性化）、NOTIFICATION TYPESセクション（Messages/Friend Requests/Announcementsの3種別トグル）、SharedPreferences保存（notification_enabled/notification_messages/notification_friend_requests/notification_announcements、デフォルト全てtrue）、注意テキスト（端末設定への案内）。FCM連携はR-10決定後にTODO。settings_screen.dartのNotificationsに遷移接続 |
| 2026-04-08 | 4-5 プライバシーポリシー画面 + 4-6 利用規約画面 | lib/screens/legal_document_screen.dart を共通ウィジェットとして作成（LegalDocumentScreen: title+assetPathパラメータ化）。flutter_markdown+url_launcherパッケージ追加。assets/privacy_policy.md・assets/terms_of_service.mdをアプリ内バンドル。rootBundle.loadStringで読み込み→MarkdownBodyでレンダリング。カスタムスタイルシート（h1:20px白/h2:18px白/h3:16px白/本文:14px#A0A0A0/リンク:#00D4FF/ビュレット:#555555）。リンクタップで外部ブラウザ起動（url_launcher）。読み込み失敗時エラーダイアログ。settings_screen.dartのPrivacy Policy・Terms of Serviceに遷移接続（アイコンをchevron_rightに変更） |
| 2026-04-09 | 4-7 サイドドロワー | lib/widgets/custom_drawer.dart を共通ウィジェットとして作成。ヘッダー（#1A1A1A背景、64pxアバター+ユーザー名+@userId+プランバッジFREE/PRO/BIZ、StreamBuilderでリアルタイム監視、タップでプロフィール設定画面遷移）。プランセクション（Freeのみ表示、rocket_launchアイコン+Upgrade to Pro+説明+View Plansカプセルボタン）。ナビリスト3項目（Subscription: credit_cardアイコン+Pro/Bizプラン名バッジ / Announcements: campaignアイコン+SharedPreferences未読件数バッジ / Settings: ボトムナビ設定タブ切替）。フッター（EMOFF v1.0.0）。ドロワー幅75%最大280px、右上右下16px角丸。home_screen.dart・talk_list_screen.dartのdrawer置き換え+TODOコメント削除。main_shell.dartでonSwitchToSettingsコールバック渡し。サブスクリプション画面遷移はTODO |
| 2026-04-09 | 4-8 サブスクリプション/課金画面 | lib/screens/subscription_screen.dart 作成。lib/services/revenue_cat_service.dart 作成（RevenueCat SDK統合）。CustomAppBar「Subscription」、ヒーローセクション「CHOOSE YOUR CLARITY」+「Plans」、現在プランバナー（Pro/Bizのみ: CURRENT PLAN+プラン名+次回請求日+Manage Subscriptionリンク）、3プランカード縦並び（Free: ¥0+機能4行+Current Planボタン / Pro: シアンボーダー2px+RECOMMENDEDバッジ+¥300シアン+Upgrade to Proボタン / Business: opacity 60%+COMING SOONバッジ+タップ不可）、注釈セクション（自動更新説明+利用規約/プライバシーポリシーリンク+Restore Purchasesリンク）。購入フロー: RevenueCat purchase()→成功ダイアログ（check_circle緑）/失敗ダイアログ（error赤）/キャンセル無操作。Firestore users/{uid}.plan+planExpiresAt更新。購入復元対応。splash_screen.dart/login_screen.dart/registration_screen.dartにRevenueCat初期化追加。custom_drawer.dart×2+talk_list_screen.dart+talk_room_screen.dart×2の計5箇所のTODO解消→遷移接続完了。FIRESTORE.mdにplan/planExpiresAtフィールド追加。**全25画面の実装完了** |
| 2026-04-05 | 3-6 グループ管理画面 | lib/screens/group_management_screen.dart 作成。CustomAppBar「Group Settings」、グループ情報セクション（96pxアイコン+カメラオーバーレイ作成者のみ+グループ名インライン編集+メンバー数表示）、MEMBERSセクション（OWNER/YOUバッジ、ソート順: 作成者→自分→名前昇順、メンバー追加ボタン+削除ボタン作成者のみ）、メンバー追加ボトムシート（DraggableScrollableSheet: 検索バー+友達リスト+既存メンバーグレーアウト「参加中」+チェック式選択+追加ボタン）、メンバー削除確認ダイアログ（danger）、グループ退出確認ダイアログ（作成者/一般で文言分岐）、退出時popUntilでメインシェルへ、画像選択ボトムシート（MVPはTODO）、メンバータップ→友達プロフィール画面遷移（友達のみ）。talk_room_screen.dartのグループ管理メニューTODOに遷移接続。**フェーズ3（コア機能画面）全画面の実装完了** |
