# APP_SCREENS.md

> 最終更新: 2026-04-03（トーク一覧画面追加）

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
- **遷移先**: 友達プロフィール画面（未実装）、友達申請画面（未実装）、サイドドロワー（未実装）

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
- **遷移先**: トークルーム画面（未実装）、新規トーク作成（未実装）、プロフィール設定画面（未実装）、サイドドロワー（未実装）

### ボトムナビゲーション（メインシェル）
- **概要**: 認証後のメイン画面。ホーム・トーク・設定の3タブをボトムナビゲーションで切り替える
- **ファイル**: `lib/screens/main_shell.dart`
- **主な仕様**:
  - `IndexedStack` によるタブ切り替え（状態保持）
  - ホームタブ: `HomeScreen`（実装済み）
  - トークタブ: `TalkListScreen`（実装済み）
  - 設定タブ: プレースホルダー（フェーズ2で実装予定）
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

---

## 実装済み共通ウィジェット

| ウィジェット | ファイル | 用途 |
|---|---|---|
| `CustomButton` | `lib/widgets/custom_button.dart` | アプリ内ボタン。primary / secondary / danger の3バリエーション。`icon`（トレーリングアイコン）・`height`（高さ指定）対応 |
| `CustomDialog` | `lib/widgets/custom_dialog.dart` | ダイアログUI。Flutter標準の `AlertDialog` の代替 |
| `CustomDialogHelper` | `lib/widgets/custom_dialog_helper.dart` | `showCustomDialog` / `showCustomConfirmDialog` / `toUserFriendlyError` |
| `CustomTextField` | `lib/widgets/custom_text_field.dart` | テキスト入力。角丸16px・ダーク背景・シアン枠線 |
| `CustomAppBar` | `lib/widgets/custom_app_bar.dart` | AppBar。黒背景・シアンアクセント |
| `CustomLoadingIndicator` | `lib/widgets/custom_loading_indicator.dart` | ローディングスピナー。シアン色の回転インジケーター |
