#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_SRC="/Applications/SOTAO57 Basic Mac Tools.app"
DIST_DIR="$ROOT/dist"
DMG_NAME="SOTAO57-Basic-Mac-Tools-v1.0.0.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
STAGE="$(mktemp -d /tmp/sotao57_dmg_stage.XXXXXX)"
trap 'rm -rf "$STAGE"' EXIT

if [ ! -d "$APP_SRC" ]; then
    echo "App não encontrado em $APP_SRC. Corra ./scripts/build.sh primeiro." >&2
    exit 1
fi

mkdir -p "$DIST_DIR"

cp -R "$APP_SRC" "$STAGE/SOTAO57 Basic Mac Tools.app"
ln -s /Applications "$STAGE/Applications"
cp "$ROOT/LICENSE" "$STAGE/LICENSE.txt"

cat > "$STAGE/Instalar Dependencias Opcionais.command" <<'CMD'
#!/bin/bash
echo "================================================="
echo " SOTAO57 Basic Mac Tools — Dependencias Opcionais"
echo "================================================="
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew nao encontrado."
    echo "Instale o Homebrew primeiro em https://brew.sh e depois execute:"
    echo "  brew install ffmpeg pandoc qpdf ghostscript webp"
    echo "  brew install --cask libreoffice"
    read -r -p "Pressione Enter para fechar..."
    exit 1
fi

echo "Instalando motores opcionais via Homebrew (ffmpeg, pandoc, qpdf, ghostscript, webp)..."
brew install ffmpeg pandoc qpdf ghostscript webp || true

read -r -p "Deseja instalar tambem o LibreOffice (para DOCX/XLSX/ODS -> PDF)? [s/N] " resp
if [[ "$resp" =~ ^[sSyY]$ ]]; then
    brew install --cask libreoffice || true
fi

echo "Concluido! Pressione Enter para fechar."
read -r
CMD
chmod +x "$STAGE/Instalar Dependencias Opcionais.command"

cat > "$STAGE/LEIA-ME.txt" <<'TXT'
SOTAO57 BASIC MAC TOOLS v1.0.0
Copyright (c) 2026 Fernando Amorim (SOTAO57) — Licenca MIT

COMO INSTALAR:
1. Arraste "SOTAO57 Basic Mac Tools.app" para a pasta "Applications" (Aplicacoes).
2. Se ao abrir pela primeira vez o macOS avisar sobre programador nao verificado:
   Clique com o botao direito em "SOTAO57 Basic Mac Tools.app" -> "Abrir"
   (ou Ajustes do Sistema -> Privacidade e Seguranca -> "Abrir Mesmo Assim").
3. Opcional: execute "Instalar Dependencias Opcionais.command" se ainda nao tiver
   ffmpeg, pandoc, qpdf, ghostscript ou LibreOffice nesse Mac.

OCR com Apple Vision, conversao nativa de imagens (PNG/JPG/HEIC/TIFF/PDF),
extracao/juncao de PDFs e audio AAC/WAV funcionam imediatamente sem instalacoes extras.
TXT

rm -f "$DMG_PATH"
hdiutil create \
    -volname "SOTAO57 Basic Mac Tools" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

hdiutil verify "$DMG_PATH"
echo "DMG_OK: $DMG_PATH"
ls -lh "$DMG_PATH"
