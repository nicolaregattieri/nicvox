#!/bin/bash

# Configurações
GITHUB_USER="nicolaregattieri"
REPO_NAME="nicvox"
APP_NAME="NicVox"
DMG_NAME="NicVox_Installer.dmg"

echo "🚀 Iniciando instalação do $APP_NAME..."

# 1. Obter a URL da última versão (Release) ou do arquivo no repo
# Se você usar Releases do GitHub (recomendado), esta linha pega o arquivo do release mais recente:
URL="https://github.com/$GITHUB_USER/$REPO_NAME/releases/latest/download/$DMG_NAME"

# Se você apenas subir o DMG na raiz do repo, use esta (não recomendado para arquivos grandes):
# URL="https://github.com/$GITHUB_USER/$REPO_NAME/raw/main/$DMG_NAME"

echo "📥 Baixando instalador..."
curl -L "$URL" -o "/tmp/$DMG_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Erro ao baixar o arquivo. Verifique se a URL está correta e o repo é público."
    exit 1
fi

echo "💿 Montando imagem de disco..."
hdiutil attach "/tmp/$DMG_NAME" -mountpoint "/tmp/nicvox_mount" -quiet

echo "🚚 Instalando em /Applications..."
cp -R "/tmp/nicvox_mount/$APP_NAME.app" "/Applications/"

echo "🛡️  Removendo travas de segurança (Quarentena)..."
xattr -cr "/Applications/$APP_NAME.app"

echo "⏏️  Desmontando..."
hdiutil detach "/tmp/nicvox_mount" -quiet
rm "/tmp/$DMG_NAME"

echo "✅ $APP_NAME instalado com sucesso!"
echo "👉 Abra-o via Spotlight ou na pasta Aplicativos."
open "/Applications/$APP_NAME.app"
