#!/bin/bash

# Script para gerar executáveis do Expo Godot
# Certifique-se que os Export Templates estão instalados

GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_PATH="/Users/diegocredidio/Documents/repogit/expo_godot"
BUILD_DIR="$PROJECT_PATH/builds"

echo "🚀 Iniciando build dos executáveis..."

# Criar diretório de builds se não existir
mkdir -p "$BUILD_DIR"

echo "📁 Diretório de builds: $BUILD_DIR"

# Build para Windows
echo "🪟 Gerando executável para Windows..."
"$GODOT_PATH" --headless --path "$PROJECT_PATH" --export-release "Windows Desktop" "$BUILD_DIR/expo_godot_windows.exe"

# Build para macOS
echo "🍎 Gerando executável para macOS..."
"$GODOT_PATH" --headless --path "$PROJECT_PATH" --export-release "macOS" "$BUILD_DIR/expo_godot_macos.app"

echo "✅ Builds concluídos!"
echo "📂 Arquivos gerados em: $BUILD_DIR"
ls -la "$BUILD_DIR"