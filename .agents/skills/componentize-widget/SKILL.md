---
name: componentize-widget
description: emoffプロジェクトで特定のUIウィジェットを「カスタム化して」「コンポーネント化して」「共通化して」等の依頼が来たときに、lib/widgets/にカスタムウィジェットを作成し、既存の使用箇所を置き換え、UI_UX.mdにルールを追記する。「〇〇をカスタム化して」「〇〇をコンポーネント化して」「〇〇を共通ウィジェットにして」「〇〇を統一して」等の依頼が対象。
---

# Componentize Widget（UIコンポーネント化）

## 概要

特定のUIウィジェット（Button、TextField、Dialog 等）を、アプリ全体で統一されたカスタムウィジェットとして `lib/widgets/` に作成し、既存の使用箇所を置き換え、`UI_UX.md` にルールを追記する。

## 手順

ユーザーから「〇〇をカスタム化して」「〇〇をコンポーネント化して」等の依頼が来た場合は、以下を実施する。

### 1. 調査

1. `/Users/kanekohiroki/Desktop/emoff/UI_UX.md` を Read ツールで読み込み、既存ルールを確認する。
2. `/Users/kanekohiroki/Desktop/emoff/lib/widgets/` 内の既存カスタムウィジェットを確認し、命名規則・コードスタイルを把握する。
3. 対象ウィジェットがプロジェクト内でどこで使われているかを Grep ツールで検索する。

### 2. カスタムウィジェット作成

1. `/Users/kanekohiroki/Desktop/emoff/lib/widgets/` に `custom_<ウィジェット名>.dart` として作成する。
2. 以下のルールに従う：
   - クラス名は `Custom<ウィジェット名>` とする（例: `CustomButton`、`CustomTextField`）。
   - `StatelessWidget` または必要に応じて `StatefulWidget` で作成する。
   - 元のFlutterウィジェットと同じインターフェース（プロパティ）を維持し、呼び出し側の変更を最小限にする。
   - アプリのテーマ（`Theme.of(context).colorScheme`）に基づいたスタイルを適用する。
   - deprecated な API（`withOpacity` 等）は使用せず、最新の API（`withValues` 等）を使用する。

### 3. 既存の使用箇所を置き換え

1. Grep で検出したすべての使用箇所で、Flutterデフォルトウィジェットを `Custom<ウィジェット名>` に置き換える。
2. 必要な `import` 文を追加する。

### 4. UI_UX.md にルールを追記

`/Users/kanekohiroki/Desktop/emoff/UI_UX.md` に以下の形式でルールを追記する：

```markdown
## <ウィジェット名>使用ルール

- <ウィジェット名>には Flutter デフォルトの `<元のウィジェット>` を直接使用せず、**`Custom<ウィジェット名>`**（`lib/widgets/custom_<ウィジェット名>.dart`）を使用すること。
- `Custom<ウィジェット名>` はアプリ全体で統一されたスタイルを提供する。
```

### 5. 検証

1. `flutter analyze` で対象ファイルにエラーがないことを確認する。

## 対象となる依頼例

- 〇〇をカスタム化して
- 〇〇をコンポーネント化して
- 〇〇を共通ウィジェットにして
- 〇〇を統一して
- 〇〇をカスタムコンポーネントにして

## 注意事項

- 既に `lib/widgets/` に同名のカスタムウィジェットが存在する場合は、新規作成せず既存のものを更新する。
- コンポーネント化の際、元のウィジェットの機能を損なわないよう注意する。
