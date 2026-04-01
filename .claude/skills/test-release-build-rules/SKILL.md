---
name: test-release-build-rules
description: emoffプロジェクトで「アプリをテストリリースして」「TestFlightにリリースして」等の依頼が来たときに、App Store（TestFlight）向けのiOSビルド手順を実行するために使う。Androidは対象外。
---

# Test Release Build Rules

## 概要

emoffのテストリリース依頼時に、iOS向けのビルドとArchive作成を順番に実行する。Xcode Organizer に表示されるようアーカイブを作成して開くところまで行い、TestFlightへのアップロードはユーザーがGUIで手動実施する。

## 手順

ユーザーから「アプリをテストリリースして」「TestFlightにリリースして」等の依頼が来た場合は、以下を順番どおりに実施する。

1. `ios`ディレクトリで`pod install`を実行する（`cd /Users/kanekohiroki/Desktop/emoff/ios && pod install`）。
2. `flutter build ios`を実行し、App Storeリリース向けのビルドを行う。
3. Xcode Organizer に表示されるよう、既定の Archives 直下へアーカイブを作成して開く。
   - 例:
     - `archive_date=$(date "+%Y-%m-%d")`
     - `archive_name="Runner $(date "+%Y-%m-%d %H.%M").xcarchive"`
     - `archive_dir="/Users/kanekohiroki/Library/Developer/Xcode/Archives/$archive_date"`
     - `mkdir -p "$archive_dir"`
     - `xcodebuild -workspace /Users/kanekohiroki/Desktop/emoff/ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath "$archive_dir/$archive_name" archive`
     - `open -a Xcode "$archive_dir/$archive_name"`

## 注意事項

- Androidビルドは実施しない（テストリリースはApp Store / TestFlight のみ対象）。
- TestFlightへのアップロードはArchive作成後にユーザーがXcode OrganizerのGUIで手動実施する。
- 権限不足や依存エラーが出た場合は、ターミナルでコマンドを実行して確認・修正する。
- `flutter build ios` で権限エラーが出る場合は、Flutter SDK の所有権を一度だけ修正して以後の sudo を不要にする。
  - 例:
    - `sudo chown -R $(whoami) /Users/kanekohiroki/Developer/flutter`
    - `sudo chmod -R u+rwX /Users/kanekohiroki/Developer/flutter`
