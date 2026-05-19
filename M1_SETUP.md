# M1 Mac セットアップ手順

このドキュメントは Win11 から M1 Mac への開発環境移行手順です。

## 1. 必要ツールのインストール

```bash
# Homebrew（未インストールの場合）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutter SDK
brew install flutter

# Firebase CLI
npm install -g firebase-tools

# Node.js（未インストールの場合）
brew install node
```

## 2. リポジトリのクローン

```bash
git clone https://github.com/chenyl25123-blip/kyogen-app.git
cd kyogen-app
```

## 3. Flutter 依存パッケージのインストール

```bash
flutter pub get
cd ios && pod install && cd ..
```

## 4. バックエンド（Cloud Functions）のデプロイ

**初回のみ必須。これをしないとメール送信・通知が動作しません。**

```bash
bash deploy_backend.sh
```

実行中に Resend API キーを聞かれます。`re_` で始まるキーを入力してください。

## 5. 実機での確認

```bash
flutter run
```

## 現在の未対応事項

| 項目 | 内容 |
|------|------|
| APNs 未設定 | push通知が動作しない。Firebase Console → プロジェクト設定 → Cloud Messaging → APNs認証キー (.p8) をアップロードで解決 |
| Firestore DB | Firebase Console で asia-northeast1 リージョンに Firestore Database が作成されているか確認 |
| App Store URL | 上架時にプライバシーポリシーの公開URLが必要（Notion等で作成） |

## プロジェクト概要

- アプリ名: まもりんく（package名: kyogen）
- Firebase Project ID: projects-696e9
- Bundle ID: jp.kyogen.kyogen
- 主要機能: 毎日打刻 → 2日未確認でpush通知 → 3日未確認で緊急連絡先にメール

## CLAUDE.md のルール（Claude Code 使用時）

- コード変更前に必ず `git pull`
- バージョン番号・Firebase関連ファイルは変更しない
- 中文で返答
</content>
