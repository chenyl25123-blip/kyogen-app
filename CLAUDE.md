# 今日も元気 (Kyogen) — Claude Context

## プロジェクト概要
毎日1回タップする安否確認アプリ。3日間未確認で緊急連絡先にメール自動送信。

## 開発体制
- **Win11**: コード編集 → `git push`（メインのClaude Codeセッション）
- **Mac (Monterey / Intel)**: `git pull` → `flutter run` で実機・Simulator確認

## 技術スタック
- Flutter (iOS優先) + Dart 3.x
- Firebase Auth (匿名ログイン) + Cloud Firestore + FCM
- Cloud Functions (TypeScript): `functions/src/index.ts`
- Resend API (メール送信)
- Codemagic CI/CD → unsigned IPA → Sideloadly/爱思助手でiPhoneに投入

## Firebase
- Project ID: `projects-696e9`
- Bundle ID: `jp.kyogen.kyogen`
- Anonymous Auth: 有効
- `lib/firebase_options.dart` に設定値をハードコード済み
- `ios/Runner/GoogleService-Info.plist` 配置済み（.gitignore 除外済み）

## ファイル構成
```
lib/
  main.dart              # エントリポイント・Firebase初期化・ルーター
  demo_mode.dart         # const kDemoMode (--dart-define=DEMO_MODE=true)
  firebase_options.dart  # Firebase設定
  models.dart            # CheckIn / Contact / AppUser / CheckInStatus
  screens/               # onboarding, main, home, contact, settings
  services/              # auth, checkin, contact, notification
  theme/app_theme.dart   # AppColors, AppTheme (google_fonts削除済み)
functions/src/index.ts   # Cloud Functions
codemagic.yaml           # CI/CD (unsigned IPA)
```

## 既知の状態・注意点
- `google_fonts` は削除済み → system TextStyle 使用
- Firebase instance は全て `late final`（Demo モード時に初期化されないよう）
- `saveToken()` は non-blocking（APNs未設定でも起動する）
- iOS deployment target 警告あり（11.0 → 12.0 に上げると消える）
- Demo モード: `flutter run --dart-define=DEMO_MODE=true`（Firebase不要）

## Mac でのセットアップ
```bash
flutter pub get
cd ios && pod install && cd ..
flutter run          # iPhone または Simulator
```

## Win11 Claude との同期
Win11側で変更 → `git push` → Mac側で `git pull` → `flutter run` で確認。
変更内容はコミットメッセージで追える。
