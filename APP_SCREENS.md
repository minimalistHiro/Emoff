# APP_SCREENS.md

> 最終更新: 2026-04-09（サブスクリプション画面実装完了）

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
│               ├── [ハンバーガーメニュー] → サイドドロワー
│               ├── 友達プロフィール画面
│               │         └── [トークボタン] → トークルーム画面
│               ├── 友達申請画面
│               └── 友達申請管理画面
│
├── トークタブ
│     └── トーク一覧画面
│               ├── [ハンバーガーメニュー] → サイドドロワー
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

[サイドドロワー] ← ホーム画面・トーク一覧画面の左端メニューから展開
├── [アバタータップ] → プロフィール設定画面
├── Subscription → サブスクリプション画面
│                    ├── [Upgrade to Pro] → OS課金シート → 成功/失敗ダイアログ
│                    ├── [Restore Purchases] → 購入復元
│                    ├── [利用規約] → 利用規約画面
│                    └── [プライバシーポリシー] → プライバシーポリシー画面
├── Announcements → お知らせ画面
└── Settings → 設定タブに切替
```

---

## 実装済み画面

### スプラッシュ画面
- **概要**: アプリ起動時に「EMOFF」ロゴ + タグライン「Emotion off.」を表示し、Firebase Authの認証状態を判定して遷移先を分岐する
- **ファイル**: `lib/screens/splash_screen.dart`
- **設計書**: `plans/completed/20260403_splash_screen_design.md`
- **主な仕様**:
  - FadeIn + ScaleUp（600ms）でロゴ表示、続いてローディングインジケーターをFadeIn（300ms）
  - アンビエントグロー（シアン, opacity 4%, blur 150px）の背景演出
  - 最低表示時間1.5秒を保証
  - 認証済み → MainShell、未認証 → LoginScreen へ `pushReplacement` + フェード遷移

### ログイン画面
- **概要**: メールアドレス + パスワードでログインする画面。「Welcome Back — Access your workspace for clarity.」のコピーでEmoffの哲学を訴求
- **ファイル**: `lib/screens/login_screen.dart`
- **設計書**: `plans/completed/20260403_login_screen_design.md`
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
- **設計書**: `plans/completed/20260403_registration_screen_design.md`
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
- **遷移先**: オンボーディング画面（AI同意後）、ログイン画面（Loginリンク）、利用規約画面（実装済み）、プライバシーポリシー画面（実装済み）

### オンボーディング画面
- **概要**: AI処理同意後に表示する3スライドのチュートリアル画面。Emoffのコンセプト・使い方・安心感を伝える
- **ファイル**: `lib/screens/onboarding_screen.dart`
- **設計書**: `plans/completed/20260403_registration_screen_design.md`（Part 3）
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
- **設計書**: `plans/completed/20260403_home_friends_screen_design.md`
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
- **遷移先**: 友達プロフィール画面（実装済み）、友達申請画面（実装済み）、友達申請管理画面（実装済み）、サイドドロワー（実装済み）

### トーク一覧画面（Communication Hub）
- **概要**: 過去のトーク履歴を新着順に一覧表示する画面。個別チャットとグループチャットを統合的に表示
- **ファイル**: `lib/screens/talk_list_screen.dart`
- **設計書**: `plans/completed/20260403_talk_list_screen_design.md`
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
- **遷移先**: トークルーム画面（実装済み）、グループ作成画面（実装済み、Freeプランはアップグレード促進ダイアログ）、プロフィール設定画面（実装済み）、サイドドロワー（実装済み）

### 設定画面
- **概要**: 各種設定項目の一覧を表示する画面。上部にユーザープロフィールのサマリー、中央に設定項目リスト、下部にログアウト・バージョン情報を配置
- **ファイル**: `lib/screens/settings_screen.dart`
- **設計書**: `plans/completed/20260403_settings_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタンなし、「Settings」タイトル左寄せ）
  - プロフィールサマリー: アバター96×96px（`#242424`背景、角丸円形）+ ユーザー名（ExtraBold, 24px）+ メールアドレス（`#A0A0A0`, 14px）+「Edit Profile」ボタン（`#242424`背景、シアンテキスト、角丸12px）
  - データ取得: `users/{uid}` を StreamBuilder でリアルタイム監視
  - CONFIGURATIONセクション: Notifications（`chevron_right`）/ Account Settings（`chevron_right`）/ Announcements（`chevron_right`）
  - LEGAL & PRIVACYセクション: Privacy Policy（`chevron_right`）/ Terms of Service（`chevron_right`）
  - ログアウトボタン: CustomButton（danger, 高さ44px）+「Logout of Session」、確認ダイアログ（`showCustomConfirmDialog`）→ `AuthService.signOut()` → ログイン画面へ `pushAndRemoveUntil`
  - バージョン情報: 「VERSION 1.0.0 • EMOFF STOIC」（`#555555`, 10px, レタースペーシング広め）
  - iPhone SE対応: `SingleChildScrollView` によるスクロール構成
- **遷移先**: プロフィール設定画面（実装済み）、通知設定画面（実装済み）、アカウント設定画面（実装済み）、お知らせ画面（実装済み）、プライバシーポリシー画面（実装済み）、利用規約画面（実装済み）、ログイン画面（ログアウト時）

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
- **遷移先**: グループ管理画面（実装済み、グループチャットのメニュー「グループ管理」）

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
- **遷移先**: 友達申請管理画面（実装済み、「申請が届いています」ボタン）

### 友達申請管理画面（Pending Connections）
- **概要**: 受信した友達申請の一覧を表示し、承認・拒否を行う画面。リアルタイムリスナーで申請の追加・変更を即時反映する
- **ファイル**: `lib/screens/friend_request_management_screen.dart`
- **設計書**: `plans/completed/20260403_friend_request_management_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタン付き、「REQUESTS」タイトル、大文字・セミボールド・レタースペーシング広め）+ 未処理件数バッジ（シアン円形、StreamBuilderでリアルタイム更新）
  - セクションヘッダー: 「受信した友達申請」セミボールド16px + 「N件の申請」右端（`#A0A0A0`, 14px）
  - 申請カード: `#1A1A1A`背景・角丸16px・パディング16px。アバター48×48px + 申請者名（ボールド16px）+ @userId（13px、`users`コレクションから非同期取得+キャッシュ）+ 相対日時（12px, `#555555`）+ 承認ボタン（CustomButton primary, 36px×96px）+ 拒否ボタン（CustomButton secondary, 36px×96px）
  - 承認フロー: 確認ダイアログ（`showCustomConfirmDialog`「〇〇さんの友達申請を承認しますか？」）→ バッチ書き込み（friend_requests.status更新 + 双方向friends作成）→ カードフェードアウト → 成功ダイアログ「〇〇さんと友達になりました」
  - 拒否フロー: 確認ダイアログ → friend_requests.status更新 → カードフェードアウト（ダイアログなし、静かに処理）
  - 二重タップ防止: 処理中のボタンを即座に非活性化（ローディング状態）
  - 空状態: `mail_outline`アイコン64px + 「友達申請はありません」+ 「新しい申請が届くとここに表示されます」（画面中央）
  - 相対日時表示: たった今 / N分前 / N時間前 / N日前 / MM/DD形式（7日以上）
  - データ取得: `friend_requests` コレクションを `where('toUid', '==', myUid).where('status', '==', 'pending').orderBy('createdAt', descending: true)` で StreamBuilder リアルタイム監視
  - iPhone SE対応: `ListView.builder` によるスクロール構成
- **遷移元**: ホーム画面（AppBarのmail_outlineバッジ付きアイコン）、友達申請画面（「申請が届いています」ボタン）

### 友達プロフィール画面（Peer Profile）
- **概要**: 友達の背景画像・アイコン・アカウント情報を表示するプロフィール画面。LINEのプロフィール画面に相当し、下部にトークボタンを配置。ホーム画面の友達リストからカードをタップして遷移
- **ファイル**: `lib/screens/friend_profile_screen.dart`
- **設計書**: `plans/completed/20260403_friend_profile_screen_design.md`
- **主な仕様**:
  - 透過AppBar: `extendBodyBehindAppBar: true`。戻るアイコン + メニューアイコン（共にドロップシャドウ付き白色、背景画像上の視認性確保）
  - ポップアップメニュー: 「ブロック」（`block`アイコン、`#FF4D4D`赤テキスト）/ 「通報」（`flag`アイコン、`#A0A0A0`、準備中ダイアログ）。`#242424`背景、角丸12px
  - 背景画像エリア: 全幅240px、`users.backgroundUrl` を `BoxFit.cover` で表示。未設定時はグラデーション（`#1A1A1A` → `#242424`）。下部に黒半透明グラデーションオーバーレイ
  - プロフィールアイコン: 96×96px円形、白ボーダー2px、ドロップシャドウ。背景画像の下端から半分はみ出す配置（Stack + Positioned）。未設定時は`person`アイコン + `#1A1A1A`背景
  - ユーザー情報: ユーザー名（ボールド24px、中央寄せ）+ @userId（14px、`#A0A0A0`）+ 区切り線（`#242424`、bio存在時のみ）+ 自己紹介文（14px、`#A0A0A0`、最大5行、中央寄せ）。左右パディング32px
  - トークボタン: `bottomNavigationBar` に固定配置、CustomButton primary、`chat_bubble_outline`アイコン付き。左右マージン24px
  - トーク開始ロジック: `friends/{friendUid}.chatId` が存在すれば既存チャットを開く。なければ新規 `chats` ドキュメント作成（type: direct）+ 両方の `friends` サブコレクションに `chatId` を書き戻し → TalkRoomScreen 遷移
  - ブロック確認ダイアログ: `block`アイコン48px（`#FF4D4D`）+ 影響3点箇条書き（メッセージ不着・友達リスト相互削除・相手通知なし）+ キャンセル/ブロック横並びボタン
  - ブロック処理: `blocked_users/{friendUid}` に `blockedAt` ドキュメント作成 + 両者の `friends` サブコレクションから相互削除（バッチ書き込み）→ ホーム画面に pop
  - ユーザー不存在時: エラーダイアログ「このユーザーは存在しません」→ ホーム画面に pop
  - データ取得: `users/{friendUid}` からワンショット取得
- **遷移元**: ホーム画面（友達カードタップ）
- **遷移先**: トークルーム画面（トークボタン）、ホーム画面（ブロック成功時 pop）

### グループ作成画面（Assemble Your Circle）
- **概要**: 友達リストからメンバーを選択し、新しいグループチャットを作成する画面。トーク一覧画面の「New Discussion」ボタンから遷移。Freeプランユーザーはアップグレード促進ダイアログが表示されこの画面には到達しない
- **ファイル**: `lib/screens/group_creation_screen.dart`
- **設計書**: `plans/completed/20260403_group_creation_screen_design.md`
- **主な仕様**:
  - Freeプラン制御: `users/{uid}.plan`フィールドで判定（未設定はfree扱い）。Freeユーザーにはトーク一覧画面でアップグレード促進ダイアログ（CustomDialog: `groups`アイコン+説明+プランを見る/あとでボタン）を表示
  - CustomAppBar（戻るボタン付き、「New Group」タイトル、セミボールド）+ 右端「Create」テキストボタン（有効時シアン/無効時`#555555`）
  - グループ情報セクション: `#1A1A1A`背景、80×80pxグループアイコン（`groups`アイコン+カメラオーバーレイ、画像選択はTODO）+ グループ名入力（CustomTextField、50文字上限カウンター付き）。横並びRow
  - 選択済みメンバープレビュー: 「MEMBERS」ラベル（大文字・レタースペーシング広め）+ 選択数シアン表示 + 横スクロールチップリスト（32×32pxアバター+名前+`close`削除ボタン、`#242424`背景カプセル型）。メンバー0人時は非表示
  - 友達検索バー: カプセル型（StadiumBorder）、`search`アイコン付き、`#1A1A1A`背景、名前・IDでリアルタイムフィルタリング
  - 友達リスト: `users/{uid}/friends`サブコレクションをStreamBuilderでリアルタイム監視。チェック式選択/解除（アイテム全体タップ可）。48×48pxアバター（未選択: グレースケール20%、選択: カラー化）+名前+@userId+チェックマーク（選択: シアン塗りつぶし+白チェック、未選択: `#555555`枠線のみ）。選択済みは`#1A1A1A`ハイライト背景
  - Empty State: `person_add`アイコン48px + 「友達を追加してからグループを作成しましょう」+ 「友達を追加」ボタン（CustomButton primary, 200px幅）→ 友達申請画面遷移
  - 固定フッター: `#0D0D0D`背景+上部1px区切り線。「N人のメンバーを選択中」テキスト + 「グループを作成」ボタン（CustomButton primary、横幅いっぱい）。有効条件: グループ名1文字以上 AND メンバー1人以上
  - 破棄確認ダイアログ: 入力中に戻るボタンで表示。「作成を中止しますか？」+「入力した内容は保存されません。」+ 中止する（danger）/続ける（secondary）
  - グループ作成処理: Firestore `chats`にドキュメント作成（type:group, members, groupName, createdBy, timestamps）→ 成功時トークルーム画面へ`pushReplacement`遷移
  - `PopScope`で戻るジェスチャー制御（入力中は破棄確認ダイアログ表示）
  - iPhone SE対応: `CustomScrollView` + `SliverList` によるスクロール構成
- **遷移元**: トーク一覧画面（New Discussionボタン、Pro以上のユーザーのみ）
- **遷移先**: トークルーム画面（グループ作成成功時、pushReplacement）、友達申請画面（Empty State「友達を追加」ボタン）

### グループ管理画面（Circle Settings）
- **概要**: グループチャットの情報確認・編集・メンバー管理を行う画面。トークルーム画面の`more_vert`メニューから「グループ管理」を選択して遷移。グループ作成者（`createdBy`）と一般メンバーで操作権限が異なる
- **ファイル**: `lib/screens/group_management_screen.dart`
- **設計書**: `plans/completed/20260403_group_management_screen_design.md`
- **主な仕様**:
  - 権限モデル: 作成者のみ→グループ名編集・アイコン変更・メンバー削除。全員→メンバー追加・グループ退出
  - CustomAppBar（戻るボタン付き、「Group Settings」タイトル、セミボールド）
  - グループ情報セクション: 96×96pxグループアイコン（`groups`アイコン、作成者のみカメラオーバーレイ`#00D4FF`背景）+グループ名（ボールド22px、作成者のみ`edit`アイコン16px付き）+メンバー数（「N members」形式、14px、`#A0A0A0`）。中央寄せColumn、上下パディング32/24px、下部1px区切り線
  - グループ名インライン編集（作成者のみ）: editアイコンタップでCustomTextField+check/closeアイコン切替。50文字上限カウンター付き。確定→Firestore `groupName`更新、キャンセル→変更破棄
  - 画像選択ボトムシート（作成者のみ）: 「写真を撮る」/「ギャラリーから選択」/「キャンセル」。`#242424`背景、角丸上部24px、ハンドルバー付き（MVPはTODO）
  - MEMBERSセクション: 「MEMBERS」大文字ラベル（12px、レタースペーシング広め）+ メンバー数シアン表示
  - メンバー追加ボタン: `person_add`アイコン24px+`#242424`背景48px円形+「メンバーを追加」シアンテキスト。最上部に配置
  - メンバーリスト: 48×48pxアバター（グレースケール20%）+ 名前（ボールド16px）+ @userId（13px）+ OWNERバッジ（`#00D4FF`背景・黒テキスト・カプセル型9px）+ YOUバッジ（`#242424`背景・`#A0A0A0`テキスト）+ 削除ボタン（`remove_circle_outline`、`#FF4D4D`、作成者のみ表示・自分自身には非表示）。ソート順: 作成者→自分→名前昇順
  - メンバー追加ボトムシート: DraggableScrollableSheet（70%/90%）、ハンドルバー+「メンバーを追加」タイトル+カプセル型検索バー+友達リスト（StreamBuilder）。既存メンバーはグレーアウト（50%グレースケール+「参加中」ラベル+チェックマーク非表示+タップ不可）。新規メンバーはチェック式選択（グループ作成画面と同一仕様）。固定フッター「追加する (N)」ボタン（CustomButton primary）
  - メンバー削除確認ダイアログ: 「メンバーを削除しますか？」+ 「{名前}をこのグループから削除します。」+ 削除する（danger）/キャンセル（secondary）。Firestore `members`配列からUID除去
  - グループ退出確認ダイアログ: 「グループを退出しますか？」+ 作成者向け警告文（編集・削除権限喪失の明示）/ 一般メンバー向け文言（再参加に招待が必要）。退出する（danger）/キャンセル（secondary）。Firestore `members`配列から自分のUID除去→`popUntil`でメインシェルへ遷移
  - メンバータップ: 友達のみ友達プロフィール画面へ遷移。自分自身・非友達はタップ不可
  - データ取得: `chats/{chatId}`をStreamBuilderでリアルタイム監視（メンバー追加/削除/名前変更を即時反映）。メンバー情報は`users`コレクションからFutureBuilderで取得+キャッシュ。友達判定は`users/{uid}/friends`から初期ロード
- **遷移元**: トークルーム画面（グループチャットのメニュー「グループ管理」）
- **遷移先**: 友達プロフィール画面（メンバータップ、友達のみ）、メインシェル（グループ退出時、popUntil）

### プロフィール設定画面（Edit Profile）
- **概要**: 自分のプロフィール（背景画像・アイコン・名前・ユーザーID・自己紹介文）を編集する画面。設定画面の「Edit Profile」ボタンから遷移。友達プロフィール画面（閲覧専用）と視覚的に対応しつつ、各要素が編集可能
- **ファイル**: `lib/screens/profile_settings_screen.dart`
- **設計書**: `plans/completed/20260403_profile_settings_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタン付き、「Edit Profile」タイトル、ボールド20px）
  - 背景画像エリア: 全幅200px。`users.backgroundUrl`を`BoxFit.cover`で表示。未設定時はグラデーション（`#1A1A1A`→`#242424`）。常時黒半透明オーバーレイ（opacity:0.3）+`camera_alt`アイコン32px。タップで画像選択ボトムシート表示
  - プロフィールアイコン: 96×96px円形、白ボーダー2px、ドロップシャドウ。背景画像下端から半分はみ出す配置（Stack+Positioned）。右下にシアンカメラバッジ（24×24px、`#00D4FF`背景、`camera_alt`14px）。タップで画像選択ボトムシート表示
  - 画像選択ボトムシート: ハンドルバー+タイトル（「プロフィール画像を選択」/「背景画像を選択」）+3項目（カメラで撮影/ライブラリから選択/画像を削除）。`#242424`背景、上部角丸16px。「画像を削除」は既存画像がある場合のみ表示（`#FF4D4D`テキスト+アイコン）
  - 画像クロップ: `image_cropper`パッケージ使用。アイコン:1:1アスペクト比、背景:16:9アスペクト比。ツールバー色`#0D0D0D`+`#00D4FF`
  - 入力フォーム（左右パディング24px、フィールド間隔20px）:
    - Name: CustomTextField、20文字上限（LengthLimitingTextInputFormatter）、文字数カウンター、空欄バリデーション。`users/{uid}.name`
    - User ID: CustomTextField、`@`プレフィックス（prefixIcon）、20文字上限、半角英数字+アンダースコアのみ（FilteringTextInputFormatter）、自動小文字変換（_LowercaseTextFormatter）、3文字以上バリデーション、一意性チェック（フォーカスアウト時にFirestore照会）。`users/{uid}.userId`
    - Bio: CustomTextField、150文字上限、minLines:2/maxLines:4、文字数カウンター、「保存時にAIが文章を整えます」ヒントテキスト（`#555555`）。`users/{uid}.bio`
  - Saveボタン: CustomButton primary、変更なし/バリデーションエラー/一意性チェック中は非活性
  - AI変換プレビューダイアログ: Bio変更時にSaveタップで表示。変換前テキスト（`#A0A0A0`、`#1A1A1A`背景）→矢印→変換後テキスト（`#FFFFFF`、`#1A1A1A`背景、左シアンボーダー2px）。やり直す（secondary）/確認（primary）。MVPはモック変換
  - 保存処理: Firebase Storageに画像アップロード（`users/{uid}/icon.jpg`, `users/{uid}/background.jpg`）→ Firestore `users/{uid}` 更新（name, userId, bio, iconUrl, backgroundUrl, updatedAt）→ 完了ダイアログ → 設定画面にpop
  - 破棄確認ダイアログ: 未保存変更がある状態で戻るボタンタップ時。「変更を破棄しますか？」+「編集中の内容は保存されません」+キャンセル（secondary）/破棄（danger）。PopScope連動（canPop動的制御）
  - 画像削除: Storageファイル削除 + Firestoreフィールドをnullに更新
  - エラーハンドリング: `toUserFriendlyError()`変換、画像アップロード失敗時はテキスト変更も保存しない（アトミック）
- **遷移元**: 設定画面（Edit Profileボタン）
- **遷移先**: 設定画面（保存完了後 / 破棄後 pop）

### アカウント設定画面（Account Settings）
- **概要**: メールアドレス変更・パスワード変更・ログアウト・アカウント削除を行う画面。設定画面の「Account Settings」から遷移。ACCOUNTセクション（日常的な変更操作）とDANGER ZONEセクション（破壊的操作）を視覚的に分離
- **ファイル**: `lib/screens/account_settings_screen.dart`
- **設計書**: `plans/completed/20260403_account_settings_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタン付き、「Account Settings」タイトル、ボールド20px）
  - ACCOUNTセクション: 「ACCOUNT」大文字ラベル（10px、`#A0A0A0`、レタースペーシング広め）
    - Email Address: 現在のメールアドレスをサブテキストで表示 + `chevron_right`。タップでメールアドレス変更ダイアログ
    - Password: 「••••••••」固定サブテキスト + `chevron_right`。タップでパスワード変更ダイアログ
  - DANGER ZONEセクション: 「DANGER ZONE」大文字ラベル（10px、`#FF4D4D`赤色）、上マージン48pxで視覚的分離
    - Logout: `logout`アイコン。タップでログアウト確認ダイアログ（`logout`アイコン48px赤+「ログアウトしますか？」+キャンセル/ログアウト横並び）
    - Delete Account: テキスト・`delete_forever`アイコン共に`#FF4D4D`赤色。タップでアカウント削除2段階フロー
  - メールアドレス変更ダイアログ: 現在メール表示 + 新メール入力（CustomTextField）+ パスワード入力（表示/非表示トグル）+ キャンセル/変更横並び。再認証（`reauthenticateWithCredential`）→ `verifyBeforeUpdateEmail` → Firestore `email`更新 → 完了ダイアログ（確認メール送信案内）
  - パスワード変更ダイアログ: 現在パスワード + 新パスワード + 確認の3フィールド（全て表示/非表示トグル）。バリデーション（空欄・6文字未満・不一致）。再認証 → `updatePassword` → 完了ダイアログ
  - アカウント削除フロー:
    - ステップ1 警告ダイアログ: `warning_amber`アイコン48px赤 + 影響4点箇条書き（メッセージ削除・友達解除・グループ退出・取消不可）+ キャンセル/削除に進む横並び
    - ステップ2 パスワード再入力ダイアログ: 「本人確認」+ パスワード入力 + キャンセル/アカウントを削除横並び。再認証 → Firestore `users/{uid}`削除 → Firebase Auth ユーザー削除 → ログイン画面遷移（`pushAndRemoveUntil`）
  - 全ダイアログでローディング表示（CustomLoadingIndicator）、ボタン非活性化、`toUserFriendlyError`エラー変換
  - アイテム共通: パディング上下16px左右24px、区切り線1px `#1A1A1A`
  - 関連データクリーンアップ（友達リスト・チャットメンバー・申請の削除）はCloud Functions実装時のTODO
- **遷移元**: 設定画面（Account Settingsアイテムタップ）
- **遷移先**: ログイン画面（ログアウト成功時 / アカウント削除成功時、pushAndRemoveUntil）

### 通知設定画面（Notifications）
- **概要**: プッシュ通知のON/OFFおよび通知種別ごとの設定を行う画面。設定画面の「Notifications」から遷移。メイントグル（マスタースイッチ）で全通知を一括制御し、個別の通知種別ごとにON/OFFを切り替え可能
- **ファイル**: `lib/screens/notification_settings_screen.dart`
- **設計書**: `plans/completed/20260403_notification_settings_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタン付き、「Notifications」タイトル）
  - メイントグル（Push Notifications）: 全通知の一括ON/OFF。Switch（ON: シアン`#00D4FF`、OFF: `#555555`）。サブテキスト「全ての通知を一括で管理」（14px、`#A0A0A0`）。下部に全幅区切り線（`#242424`）
  - マスタースイッチOFF時: 個別設定をopacity 0.4で非活性化し操作不可
  - NOTIFICATION TYPESセクション: 「NOTIFICATION TYPES」大文字ラベル（10px、`#A0A0A0`、レタースペーシング広め）
    - Messages: 「新しいメッセージを受信したとき」
    - Friend Requests: 「友達申請を受け取ったとき」
    - Announcements: 「アプリからのお知らせ」
  - 各アイテム: ラベル（18px、`#FFFFFF`）+ サブテキスト（14px、`#A0A0A0`）+ Switch。パディング上下16px左右24px。アイテム間区切り線（1px、`#1A1A1A`、左右24px）
  - 注意テキスト: 「通知が届かない場合は、端末の設定からEmoffの通知を許可してください」（12px、`#555555`、中央寄せ、上マージン32px）
  - データ保存: SharedPreferences（`notification_enabled` / `notification_messages` / `notification_friend_requests` / `notification_announcements`、全てbool、デフォルトtrue）。トグル操作と同時に即時保存
  - FCM連携: R-10決定後にTODO。現時点ではUI層（トグル操作+SharedPreferences保存）のみ
- **遷移元**: 設定画面（Notificationsアイテムタップ）
- **遷移先**: 設定画面（戻るボタン pop）

### お知らせ画面（Announcements）
- **概要**: アプリからのアップデート情報・システム通知を時系列で一覧表示する画面。設定画面の「Announcements」から遷移。管理者がFirebaseコンソールから投稿した `announcements` コレクションのデータをカード形式で表示
- **ファイル**: `lib/screens/announcements_screen.dart`
- **設計書**: `plans/completed/20260403_announcements_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタン付き、「Announcements」タイトル）
  - お知らせカード: `#1A1A1A`背景、角丸12px、パディング16px、左右マージン16px、カード間マージン12px
    - タイトル: ボールド16px、`#FFFFFF`
    - 日付: 12px、`#A0A0A0`、「YYYY年M月D日」形式
    - 本文: 14px、`#A0A0A0`、最大3行で `overflow: ellipsis`
  - 展開/折りたたみ: 本文3行超で「もっと見る」（`#00D4FF`、12px）を表示。タップで全文展開→「閉じる」に切替。`AnimatedSize` でスムーズ展開
  - データ取得: `announcements` コレクション、`orderBy('createdAt', desc)`、ワンショット取得（`.get()`）
  - プルトゥリフレッシュ: `RefreshIndicator` でデータ再取得
  - 空状態: `notifications_none` アイコン（64px、`#555555`）+ 「お知らせはありません」テキスト（16px、`#555555`）
  - ローディング: `CustomLoadingIndicator`（画面中央）
  - エラー時: `showCustomDialog` でエラーダイアログ表示
- **遷移元**: 設定画面（Announcementsアイテムタップ）
- **遷移先**: 設定画面（戻るボタン pop）

### プライバシーポリシー画面 / 利用規約画面（LegalDocumentScreen）
- **概要**: プライバシーポリシーまたは利用規約の全文をマークダウンレンダリングで表示する共通画面。`title` と `assetPath` のパラメータで切り替えて再利用する
- **ファイル**: `lib/screens/legal_document_screen.dart`
- **設計書**: `plans/completed/20260403_privacy_policy_screen_design.md` / `plans/completed/20260403_terms_of_service_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタン付き、タイトルはパラメータで「Privacy Policy」/「Terms of Service」を切替）
  - データソース: `assets/privacy_policy.md` / `assets/terms_of_service.md` をアプリ内にバンドル。`rootBundle.loadString()` でワンショット読み込み
  - マークダウンレンダリング: `flutter_markdown` パッケージの `MarkdownBody` を使用。テキスト選択可能（`selectable: true`）
  - カスタムスタイルシート: h1（ボールド20px白）/ h2（ボールド18px白、上24px下8px）/ h3（ボールド16px白、上16px下4px）/ 本文（14px `#A0A0A0` 行高1.6）/ リスト（ビュレット色 `#555555`、インデント16px）/ リンク（`#00D4FF`、装飾なし）
  - リンクタップ: `url_launcher` で外部ブラウザを起動（`LaunchMode.externalApplication`）
  - ローディング: `CustomLoadingIndicator`（画面中央）
  - エラー時: `showCustomDialog` でエラーダイアログ「コンテンツの読み込みに失敗しました」
  - スクロール: `SingleChildScrollView`（パディング: 左右24px、上16px、下32px）
- **遷移元**: 設定画面（Privacy Policy / Terms of Serviceアイテムタップ）、新規登録画面（リンクタップ）
- **遷移先**: 前の画面（戻るボタン pop）

### サイドドロワー（Side Drawer）
- **概要**: ホーム画面・トーク一覧画面のAppBar左端ハンバーガーメニューから開くサイドドロワー。ユーザープロフィールサマリー、現在のプラン表示とアップグレード導線、ナビゲーションリンクを提供する共通ウィジェット
- **ファイル**: `lib/widgets/custom_drawer.dart`
- **設計書**: `plans/completed/20260403_side_drawer_design.md`
- **主な仕様**:
  - ドロワー幅: 画面幅の75%（最大280px）、`#0D0D0D`背景、右上・右下16px角丸
  - ヘッダー（`#1A1A1A`背景）: アバター64×64px（円形、未設定時イニシャル）+ ユーザー名（ボールド18px Manrope）+ @userId（14px `#A0A0A0`）+ プランバッジ（FREE: `#242424`背景`#A0A0A0`テキスト / PRO: `#00D4FF`背景黒テキスト / BIZ: `#7EEEFF`背景黒テキスト、角丸8px 10px ボールド）。アバタータップでプロフィール設定画面へ遷移
  - プランセクション（Freeユーザーのみ）: `#242424`背景角丸12px、`rocket_launch`アイコン+「Upgrade to Pro」タイトル+「Unlock unlimited messages & group chats」説明+「View Plans」カプセルボタン（シアン背景）
  - ナビゲーションリスト3項目: Subscription（`credit_card`、Pro/Bizは現在プラン名バッジ）/ Announcements（`campaign`、未読件数バッジ付き）/ Settings（`settings`、ボトムナビ設定タブへ切替）。アイテム: 16px `#FFFFFF`テキスト、24px `#A0A0A0`アイコン、タップ背景`#242424`、角丸8px、パディング上下14px左右16px
  - 未読バッジ: SharedPreferencesで最終閲覧日時を保存し、Firestoreのannouncements.createdAtと比較してカウント表示
  - フッター: 区切り線（1px `#242424`）+「EMOFF v1.0.0」（大文字10px `#555555` レタースペーシング広め、中央寄せ）
  - データ取得: `users/{uid}` を StreamBuilder でリアルタイム監視
  - `onSwitchToSettings` コールバックでMainShellのボトムナビ設定タブに切替
- **利用元**: ホーム画面（実装済み）、トーク一覧画面（実装済み）
- **遷移先**: プロフィール設定画面（アバタータップ）、サブスクリプション画面（実装済み）、お知らせ画面（実装済み）、設定タブ切替

### サブスクリプション画面（Choose Your Clarity）
- **概要**: プラン一覧の表示・比較・購入・管理を行う画面。Free ユーザーにはアップグレード訴求、Pro/Business ユーザーには現在のプラン管理を提供。RevenueCat SDK によるアプリ内課金フローを統合
- **ファイル**: `lib/screens/subscription_screen.dart`
- **設計書**: `plans/completed/20260403_subscription_screen_design.md`
- **主な仕様**:
  - CustomAppBar（戻るボタン付き、「Subscription」タイトル）
  - ヒーローセクション: 「CHOOSE YOUR CLARITY」サブラベル（大文字12px レタースペーシング広め `#A0A0A0`）+「Plans」極太タイトル（32px ExtraBold Manrope）+ 説明テキスト
  - 現在プランバナー（Pro/Businessのみ）: `#1A1A1A`背景角丸12px、「CURRENT PLAN」シアンラベル + プラン名 + 次回請求日 +「Manage Subscription」リンク（OS管理画面を開く）
  - Freeプランカード: `#1A1A1A`背景角丸16px、ボーダー1px `#242424`。¥0 forever。機能4行（check×2 + close×2 打消線）。Freeユーザーは「Current Plan」非活性ボタン
  - Personal Proプランカード（RECOMMENDED）: シアンボーダー2px強調。RECOMMENDEDバッジ（`#00D4FF`背景黒テキスト角丸12px）。¥300/month シアン色。機能4行（全checkシアン色）。Freeユーザー向け「Upgrade to Pro」ボタン（primary）、Proユーザーは「Current Plan」非活性
  - Businessプランカード（Coming Soon）: opacity 60%グレーアウト。COMING SOONバッジ（`#242424`背景）。¥600/user/month。機能4行テキスト色`#555555`。ボタン非表示（MVP選択不可）
  - 注釈セクション: 自動更新・キャンセル説明（12px `#555555`）+ 利用規約/プライバシーポリシーリンク横並び（`#00D4FF` 下線付き）+「Restore Purchases」リンク（14px `#00D4FF` 中央寄せ）
  - 購入フロー: RevenueCat SDK `Purchases.purchase()` → OS課金シート → 成功: check_circleアイコン緑+「アップグレード完了」CustomDialog → Firestore plan更新 / キャンセル: 何もしない / 失敗: errorアイコン赤+エラーメッセージCustomDialog
  - 購入復元:「Restore Purchases」→ RevenueCat `restorePurchases()` → 復元成功/該当なしダイアログ
  - プラン判定: Firestore `users/{uid}.plan` + RevenueCat `customerInfo` の両方を参照（RevenueCatが最新）
  - データ取得: Firestore `users/{uid}` ワンショット + RevenueCat `getCustomerInfo()` + `getOfferings()`
- **遷移元**: サイドドロワー「View Plans」ボタン（Free）、サイドドロワー「Subscription」ナビアイテム（全ユーザー）、トークルーム Free上限到達ダイアログ「Proプランにアップグレード」、トークルーム インプットドックロック「Proプランで無制限に →」、トーク一覧 グループ作成Freeダイアログ「プランを見る」
- **遷移先**: 利用規約画面、プライバシーポリシー画面、OS課金シート、OSサブスクリプション管理画面

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

### RevenueCatService（課金サービス）
- **概要**: RevenueCat SDK のラッパーサービス。アプリ内サブスクリプションの初期化・購入・復元・プラン判定を担う
- **ファイル**: `lib/services/revenue_cat_service.dart`
- **提供メソッド**:
  - `init()` — RevenueCat SDKの初期化（UID紐付け）。スプラッシュ画面・ログイン・新規登録の認証成功後に呼び出し
  - `getCurrentPlan()` — 現在のプラン取得（`pro` / `free`）
  - `getCustomerInfo()` — RevenueCat CustomerInfo取得
  - `getOfferings()` — 利用可能なOfferings（プラン一覧）取得
  - `purchase()` — パッケージ購入実行
  - `restorePurchases()` — 購入履歴の復元

---

## 実装済み共通ウィジェット

| ウィジェット | ファイル | 用途 |
|---|---|---|
| `CustomButton` | `lib/widgets/custom_button.dart` | アプリ内ボタン。primary / secondary / danger の3バリエーション。`icon`（トレーリングアイコン）・`height`（高さ指定）対応 |
| `CustomDialog` | `lib/widgets/custom_dialog.dart` | ダイアログUI。Flutter標準の `AlertDialog` の代替 |
| `CustomDialogHelper` | `lib/widgets/custom_dialog_helper.dart` | `showCustomDialog` / `showCustomConfirmDialog` / `toUserFriendlyError` |
| `CustomTextField` | `lib/widgets/custom_text_field.dart` | テキスト入力。角丸16px・ダーク背景・シアン枠線。`prefixIcon`・`suffixIcon`・`focusNode`・`inputFormatters`・`minLines` 対応 |
| `CustomAppBar` | `lib/widgets/custom_app_bar.dart` | AppBar。黒背景・シアンアクセント |
| `CustomLoadingIndicator` | `lib/widgets/custom_loading_indicator.dart` | ローディングスピナー。シアン色の回転インジケーター |
| `CustomDrawer` | `lib/widgets/custom_drawer.dart` | サイドドロワー。プロフィールサマリー・プランバッジ・アップグレード促進・ナビリスト（Subscription/Announcements/Settings）・未読バッジ。`onSwitchToSettings` コールバック |
