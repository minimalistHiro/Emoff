# APP_SCREENS.md

> 最終更新: 2026-04-04（友達申請画面実装完了）

**このファイルには実装済みの画面・コンポーネントのみを記載する。** 未実装の画面は IMPLEMENTATION_PROGRESS.md / DESIGN_PROGRESS.md で管理する。

---

## 画面遷移フロー（全体設計）

```
[アプリ起動]
└── スプラッシュ画面（認証状態チェック）
      ├── 認証済み → ホーム画面（ボトムナビゲーション）
      └── 未認証 → ログイン画面
                    ├── [ログイン成功] → ホーム画面
                    ├── [新規登録リンク] → 新規登録画面
                    │                       └── [登録成功] → ホーム画面
                    └── [パスワードを忘れた] → パスワードリセット画面
                                                └── [送信完了] → ログイン画面に戻る

[ボトムナビゲーション]
├── ホームタブ
│     └── ホーム画面（友達一覧）
│               ├── 友達プロフィール画面
│               │         └── [トークボタン] → トークルーム画面
│               ├── 友達申請画面
│               └── 友達申請管理画面
│
├── トークタブ
│     └── トーク一覧画面
│               ├── トークルーム画面
│               │         └── [確認ボタン] → AI変換プレビュー → [送信] → メッセージ送信
│               └── グループ作成画面
│                         └── グループ管理画面
│
└── 設定タブ
      └── 設定画面
            ├── プロフィール設定画面
            ├── 通知設定画面
            ├── アカウント設定画面
            ├── お知らせ画面
            ├── プライバシーポリシー画面
            └── 利用規約画面
```

---

## 実装済み画面

### スプラッシュ画面
- **概要**: アプリ起動時に「EMOFF」ロゴ + タグライン「Emotion off.」を表示し、Firebase Authの認証状態を判定して遷移先を分岐する
- **ファイル**: `lib/screens/splash_screen.dart`
- **設計書**: `plans/in_progress/20260403_splash_screen_design.md`
- **主な仕様**:
  - FadeIn + ScaleUp（600ms）でロゴ表示、続いてローディングインジケーターをFadeIn（300ms）
  - アンビエントグロー（シアン, opacity 4%, blur 150px）の背景演出
  - 最低表示時間1.5秒を保証
  - 認証済み → MainShell、未認証 → LoginScreen へ `pushReplacement` + フェード遷移

### ログイン画面
- **概要**: メールアドレス + パスワードでログインする画面。「Welcome Back — Access your workspace for clarity.」のコピーでEmoffの哲学を訴求
- **ファイル**: `lib/screens/login_screen.dart`
- **設計書**: `plans/in_progress/20260403_login_screen_design.md`
- **主な仕様**:
  - ブランディング領域: 「EMOFF」ロゴ（シアン、レタースペーシング広め）
  - ウェルカムヘッダー: 「Welcome Back」+ サブテキスト（左寄せ）
  - メールアドレス入力: 大文字ラベル「EMAIL ADDRESS」+ CustomTextField
  - パスワード入力: 左「PASSWORD」+ 右「FORGOT PASSWORD?」リンク + CustomTextField
  - ログインボタン: CustomButton（primary, 高さ56px）+「Login」+ 右矢印アイコン
  - 区切り線 +「New to the philosophy? Sign Up」リンク
  - アンビエントグロー: 右上シアン + 左下パープル（opacity 5%）
  - Firebase Auth認証、エラー時は `CustomDialog` + `toUserFriendlyError()` で表示
  - iPhone SE対応: `SingleChildScrollView` + `SafeArea`
- **遷移先**: パスワードリセット画面、新規登録画面、MainShell（ログイン成功時）

### 新規登録画面 + AI処理同意ポップアップ
- **概要**: メールアドレス + パスワードで新規アカウントを作成する画面。登録後にAI処理同意ポップアップを表示し、同意後にオンボーディング画面へ遷移する
- **ファイル**: `lib/screens/registration_screen.dart`
- **設計書**: `plans/in_progress/20260403_registration_screen_design.md`
- **主な仕様**:
  - ブランディング領域: 「EMOFF」ロゴ（シアン、レタースペーシング広め）
  - ウェルカムヘッダー: 「Create Account」+「Join the philosophy of clarity.」（左寄せ）
  - 入力フィールド: NAME / EMAIL ADDRESS / PASSWORD / CONFIRM PASSWORD の4項目（CustomTextField）
  - 利用規約・プライバシーポリシー同意チェックボックス（未チェック時はボタン非活性 opacity: 0.4）
  - 登録ボタン: CustomButton（primary, 高さ56px）+「Sign Up」+ 右矢印アイコン
  - 区切り線 +「Already a member? Login」リンク
  - アンビエントグロー: ログイン画面と同一（右上シアン + 左下パープル）
  - Firebase Auth アカウント作成 → Firestore `users/{uid}` ドキュメント作成（userId は空文字列、プロフィール設定画面で後設定）
  - AI処理同意ポップアップ: CustomDialog、barrierDismissible: false、番号付き4項目（Anthropicへの送信・保存期間・データ削除権利等）
  - 「同意しない」選択時はアカウントを削除して新規登録画面に留まる
  - iPhone SE対応: `SingleChildScrollView` + `SafeArea`
- **遷移先**: オンボーディング画面（AI同意後）、ログイン画面（Loginリンク）、利用規約画面（未実装）、プライバシーポリシー画面（未実装）

### オンボーディング画面
- **概要**: AI処理同意後に表示する3スライドのチュートリアル画面。Emoffのコンセプト・使い方・安心感を伝える
- **ファイル**: `lib/screens/onboarding_screen.dart`
- **設計書**: `plans/in_progress/20260403_registration_screen_design.md`（Part 3）
- **主な仕様**:
  - `PageView` による3スライド横スワイプ切り替え
  - スライド1「感情を抜く、新しいコミュニケーション」: 吹き出し + フィルターアイコン
  - スライド2「思ったまま書いて、AIにおまかせ」: 3ステップ図解（入力 → プレビュー → 送信）
  - スライド3「あなたの原文は誰にも届きません」: シールドアイコン
  - ページインジケーター: 3ドット（現在ページ シアン、非選択 `#555555`、8px円）
  - 「スキップ」テキストリンク（右上、全スライド共通）
  - スライド1〜2:「次へ」ボタン、スライド3:「はじめる」ボタン（CustomButton primary）
- **遷移先**: MainShell（「はじめる」/「スキップ」タップ時、pushReplacement）

### パスワードリセット画面
- **概要**: 登録済みメールアドレスにパスワードリセットリンクを送信する画面。メールアドレス1フィールド + 送信ボタンのみのシンプル構成
- **ファイル**: `lib/screens/password_reset_screen.dart`
- **設計書**: `plans/completed/20260403_password_reset_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタン付き、タイトルなし）
  - ヘッダー: 「Reset Password」+ 説明テキスト（左寄せ）
  - メールアドレス入力: 大文字ラベル「EMAIL ADDRESS」+ CustomTextField
  - 送信ボタン: CustomButton（primary, 高さ56px）+「Send Reset Link」+ 右矢印アイコン
  - 「Back to Login」リンク（中央寄せ）
  - アンビエントグロー: ログイン画面と同一（右上シアン + 左下パープル）
  - Firebase Auth `sendPasswordResetEmail()` でリセットリンク送信
  - 送信完了ダイアログ: CustomDialog「メール送信完了」+「ログイン画面に戻る」ボタン（barrierDismissible: false）
  - エラー時は `toUserFriendlyError()` で日本語変換し CustomDialog で表示
  - iPhone SE対応: `SingleChildScrollView` + `SafeArea`
- **遷移先**: ログイン画面（pop）

### ホーム画面（友達一覧）
- **概要**: 友達登録済みのユーザー一覧を表示するメイン画面。「Circle of Clarity（明晰さの輪）」コンセプト
- **ファイル**: `lib/screens/home_screen.dart`
- **設計書**: `plans/in_progress/20260403_home_friends_screen_design.md`
- **主な仕様**:
  - AppBar: ハンバーガーメニュー（左）、「FRIENDS」タイトル（大文字・レタースペーシング広め）、友達追加アイコン（右①）、検索アイコン（右②）
  - ヒーローセクション: 「Circle of Clarity」極太タイトル（36px, ExtraBold）+ サブテキスト
  - 検索バー: カプセル型（StadiumBorder）、filter_listアイコン付き、タップでAppBarが検索フィールドに変化、リアルタイムフィルタリング
  - 友達リスト: カード形式（`#1A1A1A`背景、角丸16px、パディング20px）、アバター56×56px（グレースケール→カラーアニメーション500ms、ColorFilter.matrix使用）+ 名前 + 「MEMBER」ラベル + chevron_right
  - 招待セクション: 破線ボーダー（CustomPainter）+ add_circleアイコン + 「Expand your objective circle」+「Invite Friend」ボタン（CustomButton primary）
  - Empty State: 友達0人時に招待セクションを画面中央に表示
  - FAB: シアン背景（`#00D4FF`）の+ボタン（右下固定）→ 友達申請画面へ遷移
  - データ取得: `users/{uid}/friends` サブコレクションをStreamBuilderでリアルタイム監視
  - iPhone SE対応: CustomScrollView + SliverList によるスクロール構成
- **遷移先**: 友達プロフィール画面（未実装）、友達申請画面（実装済み）、サイドドロワー（未実装）

### トーク一覧画面（Communication Hub）
- **概要**: 過去のトーク履歴を新着順に一覧表示する画面。個別チャットとグループチャットを統合的に表示
- **ファイル**: `lib/screens/talk_list_screen.dart`
- **設計書**: `plans/in_progress/20260403_talk_list_screen_design.md`
- **主な仕様**:
  - AppBar: ハンバーガーメニュー（左）、「EMOFF」タイトル（大文字・ボールド・レタースペーシング広め）、検索アイコン（右①）、プロフィールアバター32×32px（右②）
  - セクションヘッダー: 「COMMUNICATION HUB」サブラベル（12px, `#A0A0A0`）+ 「Chats」極太タイトル（30px, ExtraBold）+ 「New Discussion」シアンカプセルボタン（右寄せ）
  - トークリスト: チャットアイテムをカード形式で表示。個別チャットはユーザー写真（56px、グレースケール20%）、グループはMaterial Iconベースのアバター（`#242424`背景、シアンアイコン）
  - ChatItem（StatefulWidget）: 1対1チャットは `users` コレクションから相手ユーザー情報を非同期取得し、名前とアバターに使用
  - 未読判定: `lastMessageAt > lastReadAt[myUid]` でクライアント側判定。未読時はカード背景 `#1A1A1A` + シアンドット（8px）
  - 日時フォーマット: 今日→時刻（AM/PM）、1日前→Yesterday、7日以内→曜日名、それ以上→月日
  - 検索モード: AppBar切替式。グループ名またはメッセージ内容でリアルタイムフィルタリング
  - AI Concierge Readyセクション: 破線ボーダー（CustomPainter）+ `auto_awesome`アイコン + ステータスメッセージ（リスト下部）
  - Empty State: チャットが0件の場合、AI Conciergeセクションを画面中央に表示
  - データ取得: `chats` コレクションを `where('members', arrayContains: uid).orderBy('lastMessageAt', descending: true)` で StreamBuilder リアルタイム監視
  - iPhone SE対応: CustomScrollView + SliverList によるスクロール構成
- **遷移先**: トークルーム画面（実装済み）、新規トーク作成（未実装）、プロフィール設定画面（未実装）、サイドドロワー（未実装）

### 設定画面
- **概要**: 各種設定項目の一覧を表示する画面。上部にユーザープロフィールのサマリー、中央に設定項目リスト、下部にログアウト・バージョン情報を配置
- **ファイル**: `lib/screens/settings_screen.dart`
- **設計書**: `plans/completed/20260403_settings_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタンなし、「Settings」タイトル左寄せ）
  - プロフィールサマリー: アバター96×96px（`#242424`背景、角丸円形）+ ユーザー名（ExtraBold, 24px）+ メールアドレス（`#A0A0A0`, 14px）+「Edit Profile」ボタン（`#242424`背景、シアンテキスト、角丸12px）
  - データ取得: `users/{uid}` を StreamBuilder でリアルタイム監視
  - CONFIGURATIONセクション: Notifications（`chevron_right`）/ Account Settings（`chevron_right`）/ Announcements（`chevron_right`）
  - LEGAL & PRIVACYセクション: Privacy Policy（`open_in_new`）/ Terms of Service（`open_in_new`）
  - ログアウトボタン: CustomButton（danger, 高さ44px）+「Logout of Session」、確認ダイアログ（`showCustomConfirmDialog`）→ `AuthService.signOut()` → ログイン画面へ `pushAndRemoveUntil`
  - バージョン情報: 「VERSION 1.0.0 • EMOFF STOIC」（`#555555`, 10px, レタースペーシング広め）
  - iPhone SE対応: `SingleChildScrollView` によるスクロール構成
- **遷移先**: プロフィール設定画面（未実装）、通知設定画面（未実装）、アカウント設定画面（未実装）、お知らせ画面（未実装）、プライバシーポリシー画面（未実装）、利用規約画面（未実装）、ログイン画面（ログアウト時）

### トークルーム画面
- **概要**: 個別チャット画面。メッセージの送受信をリアルタイムで行う。Emoffの核心機能であるAIトーン中立化がこの画面で動作する
- **ファイル**: `lib/screens/talk_room_screen.dart`
- **設計書**: `plans/completed/20260403_talk_room_screen_design.md`
- **主な仕様**:
  - AppBar: 戻るボタン（左端）、相手の名前（セミボールド18px）+ 肩書き（大文字10px、`#555555`）、検索アイコン（右①）、メニューアイコン（右②）
  - メッセージキャンバス: `chats/{chatId}/messages` を StreamBuilder でリアルタイム監視（降順取得、reverse ListView）
  - 日付インジケーター: カプセル型ピル（`#1A1A1A`背景）、「MONDAY, APRIL 3」形式の大文字表示
  - 受信バブル: 左寄せ、`#242424`背景、角丸16px、パディング上下16px左右20px、最大幅85%
  - 送信バブル: 右寄せ、`#1A3A4A`背景、角丸16px、軽いドロップシャドウ
  - トーンバッジ: 送信メッセージに付与（NEUTRALIZED/BUSINESS/CASUAL/CONCISE）、`#5E5C78`背景
  - タイムスタンプ: AM/PM形式（10px, `#A0A0A0`）
  - グループチャット対応: 受信メッセージに送信者名を表示
  - インプットドック: 添付ファイルアイコン + カプセル型テキスト入力 + トーン選択チップ（Pro以上）+ 「CONFIRM」ボタン
  - AI変換プレビュートレイ: CONFIRM→スライドアップトレイ、Original Draft/Emoff-ed Version 2カラム比較、SEND NEUTRALIZED/REFINE AI ボタン（MVPはモック変換）
  - オプションメニュー: 通報する（1対1のみ）/ ブロック（1対1のみ）/ グループ管理（グループのみ）
  - 通報フロー: メニューからのユーザー通報 + メッセージ長押しからのメッセージ通報。理由4択+補足入力→Firestore reports保存
  - ブロック確認ダイアログ: 3点説明+ブロック/キャンセルボタン、成功時トーク一覧へ遷移
  - Free上限到達UI: 残数カウンター（プログレスバー）、残り5通警告バナー、上限到達ダイアログ、インプットドックロック、アップグレード導線
  - トーン選択UI: 4トーン（ニュートラル/ビジネス敬語/カジュアル/簡潔）、チャットごとにSharedPreferences保存、Pro以上のみチップ表示
  - トーク内検索: 検索モードAppBar、クライアントサイドフィルター
- **遷移元**: トーク一覧画面（チャットアイテムタップ）

### 友達申請画面（Find & Connect）
- **概要**: ユーザーIDで他のユーザーを検索し、友達申請を送信する画面。ホーム画面のperson_addアイコン・Invite Friendボタン・FABから遷移
- **ファイル**: `lib/screens/friend_request_screen.dart`
- **設計書**: `plans/completed/20260403_friend_request_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタン付き、「ADD FRIEND」タイトル、大文字・セミボールド・レタースペーシング広め）
  - 説明セクション: 「IDで友達を検索」ボールド20px +「相手のユーザーIDを入力して友達申請を送りましょう」サブテキスト14px
  - 検索入力: `@`プレフィックス付きCustomTextField（`prefixIcon`使用）+ 円形検索ボタン（48×48px、シアン背景）、入力がない場合はボタン非活性（`#555555`）
  - 入力バリデーション: 半角英数字+アンダースコアのみ（`^[a-zA-Z0-9_]+$`）、不正文字はリアルタイムエラー表示
  - 検索結果4状態切り替え: 初期（`person_search`アイコン）/ 検索中（CustomLoadingIndicator）/ ユーザー発見（カード表示）/ 未発見（`person_off`アイコン）
  - ユーザー発見カード: `#1A1A1A`背景・角丸16px、アバター72×72px（中央）、ユーザー名18px・ユーザーID14px・自己紹介文14px（最大2行）、中央寄せ縦並びレイアウト
  - 申請ボタン5パターン分岐: 通常（primary「友達申請を送る」）/ 既に友達（secondary非活性「友達です」）/ 申請済み（secondary非活性「申請済み」）/ 相手から申請受信中（primary「申請が届いています」→申請管理画面遷移）/ 自分自身（secondary非活性「自分のIDです」）
  - ブロック中ユーザー: `blocked_users`サブコレクションをチェックし「見つかりませんでした」と同じ表示（プライバシー配慮）
  - 申請送信フロー: 確認ダイアログ（`showCustomConfirmDialog`「〇〇さんに友達申請を送りますか？」）→ Firestore `friend_requests`にドキュメント作成 → 成功ダイアログ → ボタン「申請済み」に変化
  - 自分のID表示セクション: 画面下部固定、「YOUR ID」ラベル + `@myUserId`（ボールド16px）+ コピーアイコン（`content_copy`、シアン）→ クリップボードコピー + 情報ダイアログ
  - データ取得: `users`コレクション `where('userId', '==', input)` で検索、`friends`サブコレクション・`friend_requests`で関係性判定
  - iPhone SE対応: `SingleChildScrollView` + `Column` + 下部固定セクション
- **遷移元**: ホーム画面（person_addアイコン・Invite Friendボタン・FAB）
- **遷移先**: 友達申請管理画面（未実装、「申請が届いています」ボタン）

### ボトムナビゲーション（メインシェル）
- **概要**: 認証後のメイン画面。ホーム・トーク・設定の3タブをボトムナビゲーションで切り替える
- **ファイル**: `lib/screens/main_shell.dart`
- **主な仕様**:
  - `IndexedStack` によるタブ切り替え（状態保持）
  - ホームタブ: `HomeScreen`（実装済み）
  - トークタブ: `TalkListScreen`（実装済み）
  - 設定タブ: `SettingsScreen`（実装済み）
  - ラベル: 英語大文字（FRIENDS / CHATS / SETTINGS）、レタースペーシング広め
  - アクティブタブ: シアンアイコン（filled）、非アクティブ: `#555555`（outlined）
  - 上部ボーダー: 1px `#242424`

---

## 実装済みサービス

### AuthService（認証サービス）
- **概要**: Firebase Authenticationを使ったメール+パスワード認証のロジック
- **ファイル**: `lib/services/auth_service.dart`
- **提供メソッド**:
  - `signUp()` — 新規登録 + Firestore usersドキュメント作成
  - `signIn()` — ログイン
  - `signOut()` — ログアウト
  - `sendPasswordResetEmail()` — パスワードリセットメール送信
  - `isUserIdAvailable()` — userId重複チェック
  - `currentUser` — 現在のユーザー取得
  - `authStateChanges` — 認証状態の変化ストリーム

### ChatService（チャットサービス）
- **概要**: Firestoreのチャット・メッセージ・通報・ブロック操作を担うサービスクラス
- **ファイル**: `lib/services/chat_service.dart`
- **提供メソッド**:
  - `getMessages()` — メッセージのリアルタイムストリーム取得（降順、limit指定可）
  - `getChatStream()` — チャット情報のリアルタイムストリーム取得
  - `sendMessage()` — メッセージ送信（バッチ処理: messagesドキュメント作成 + chats.lastMessage/lastMessageAt更新。tone パラメータ対応）
  - `updateLastRead()` — 既読タイムスタンプ更新
  - `submitReport()` — 通報送信（Firestore reports コレクションに保存）
  - `blockUser()` — ユーザーブロック（blocked_users サブコレクションに保存）
  - `getOtherUser()` — 1対1チャットの相手ユーザー情報取得
  - `currentUid` — 現在のユーザーUID取得

---

## 実装済み共通ウィジェット

| ウィジェット | ファイル | 用途 |
|---|---|---|
| `CustomButton` | `lib/widgets/custom_button.dart` | アプリ内ボタン。primary / secondary / danger の3バリエーション。`icon`（トレーリングアイコン）・`height`（高さ指定）対応 |
| `CustomDialog` | `lib/widgets/custom_dialog.dart` | ダイアログUI。Flutter標準の `AlertDialog` の代替 |
| `CustomDialogHelper` | `lib/widgets/custom_dialog_helper.dart` | `showCustomDialog` / `showCustomConfirmDialog` / `toUserFriendlyError` |
| `CustomTextField` | `lib/widgets/custom_text_field.dart` | テキスト入力。角丸16px・ダーク背景・シアン枠線。`prefixIcon`・`suffixIcon` 対応 |
| `CustomAppBar` | `lib/widgets/custom_app_bar.dart` | AppBar。黒背景・シアンアクセント |
| `CustomLoadingIndicator` | `lib/widgets/custom_loading_indicator.dart` | ローディングスピナー。シアン色の回転インジケーター |
