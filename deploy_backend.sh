#!/bin/bash
# 今日も元気 — バックエンドデプロイスクリプト
# 使い方: bash deploy_backend.sh

set -e
cd "$(dirname "$0")"

echo ""
echo "======================================"
echo "  今日も元気 バックエンド デプロイ"
echo "======================================"
echo ""

# ── 1. 最新コード取得 ──────────────────────
echo "→ [1/6] 最新コードを取得中..."
git pull
echo "✓ 完了"
echo ""

# ── 2. Node.js 確認 ───────────────────────
echo "→ [2/6] Node.js を確認中..."
if ! command -v node &> /dev/null; then
  echo "  Node.js が見つかりません。インストール中..."
  brew install node
fi
echo "✓ Node.js: $(node --version)"
echo ""

# ── 3. Firebase CLI 確認 ──────────────────
echo "→ [3/6] Firebase CLI を確認中..."
if ! command -v firebase &> /dev/null; then
  echo "  Firebase CLI が見つかりません。インストール中..."
  npm install -g firebase-tools
fi
echo "✓ Firebase CLI: $(firebase --version | head -1)"
echo ""

# ── 4. Firebase ログイン ──────────────────
echo "→ [4/6] Firebase にログイン..."
echo "  ブラウザが開きます。Googleアカウントでログインしてください。"
echo ""
firebase login
echo ""

# ── 5. Resend API Key の設定 ──────────────
echo "→ [5/6] Resend API Key を設定中..."
if [ -f functions/.env.production ]; then
  echo "✓ functions/.env.production はすでに存在します。スキップ。"
else
  echo ""
  echo "  Resend API Key を入力してください (re_ で始まる文字列):"
  read -r RESEND_KEY_INPUT
  echo "RESEND_KEY=$RESEND_KEY_INPUT" > functions/.env.production
  echo "✓ functions/.env.production を作成しました"
fi
echo ""

# ── 6. 依存関係インストール & デプロイ ──────
echo "→ [6/6] デプロイ中..."
echo ""
cd functions && npm install && cd ..

echo ""
echo "  ⚠️  Firebase プロジェクトが Blaze（従量課金）プランであることを確認してください。"
echo "     Spark（無料）プランでは Functions をデプロイできません。"
echo "     確認: https://console.firebase.google.com/project/projects-696e9/usage"
echo ""
read -p "  準備できたら Enter キーを押してください..."
echo ""

firebase deploy --only functions,firestore:rules

echo ""
echo "======================================"
echo "  ✅ デプロイ完了！"
echo "======================================"
echo ""
echo "  Cloud Functions が稼働中です。"
echo "  毎朝 09:00 JST に自動チェックが実行されます。"
echo ""
