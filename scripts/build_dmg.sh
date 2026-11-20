#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_SRC="/Applications/SOTAO57 macOS Tools.app"
DIST_DIR="$ROOT/dist"
DMG_NAME="SOTAO57-macOS-Tools-v1.1.1.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
STAGE="$(mktemp -d /tmp/sotao57_dmg_stage.XXXXXX)"
trap 'rm -rf "$STAGE"' EXIT

if [ ! -d "$APP_SRC" ]; then
    echo "App não encontrado em $APP_SRC. Corra ./scripts/build.sh primeiro." >&2
    exit 1
fi

mkdir -p "$DIST_DIR"

cp -R "$APP_SRC" "$STAGE/SOTAO57 macOS Tools.app"
ln -s /Applications "$STAGE/Applications"
cp "$ROOT/LICENSE" "$STAGE/LICENSE.txt"

cat > "$STAGE/Instalar Dependencias Opcionais.command" <<'CMD'
#!/bin/bash
echo "================================================="
echo " SOTAO57 macOS Tools — Dependencias Opcionais"
echo "================================================="
echo "Nota: voce tambem pode instalar tudo pelo Assistente integrado dentro do App!"
echo ""
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew nao encontrado."
    echo "Abra o app SOTAO57 macOS Tools e use o Assistente integrado,"
    echo "ou instale o Homebrew em https://brew.sh e execute:"
    echo "  brew install ffmpeg yt-dlp pandoc qpdf ghostscript webp"
    echo "  brew install --cask libreoffice"
    read -r -p "Pressione Enter para fechar..."
    exit 1
fi

echo "Instalando motores opcionais via Homebrew (ffmpeg, yt-dlp, pandoc, qpdf, ghostscript, webp)..."
NONINTERACTIVE=1 HOMEBREW_NO_AUTO_UPDATE=1 brew install ffmpeg yt-dlp pandoc qpdf ghostscript webp || true

read -r -p "Deseja instalar tambem o LibreOffice (para DOCX/XLSX/ODS -> PDF)? [s/N] " resp
if [[ "$resp" =~ ^[sSyY]$ ]]; then
    NONINTERACTIVE=1 brew update --quiet || true
    NONINTERACTIVE=1 brew install --cask libreoffice || true
fi

echo "Concluido! Pressione Enter para fechar."
read -r
CMD
chmod +x "$STAGE/Instalar Dependencias Opcionais.command"

cat > "$STAGE/LEIA-ME.txt" <<'TXT'
SOTAO57 macOS Tools v1.1.1
Copyright (c) 2026 Fernando Amorim (SOTAO57) — Licenca MIT

COMO INSTALAR:
1. Arraste "SOTAO57 macOS Tools.app" para a pasta "Applications" (Aplicacoes).
2. Se ao abrir pela primeira vez o macOS avisar sobre programador nao verificado:
   Clique com o botao direito em "SOTAO57 macOS Tools.app" -> "Abrir"
   (ou Ajustes do Sistema -> Privacidade e Seguranca -> "Abrir Mesmo Assim").
3. Ao abrir pela primeira vez, o Assistente integrado do app verifica automaticamente
   as dependencias instaladas, pede autorizacao ao macOS (com senha se necessario),
   mostra o progresso e reinicia o app ao concluir.

NOVIDADES DA v1.1.1:
- Atualiza automaticamente o indice do Homebrew antes de instalar casks (corrige erro 404 do LibreOffice) e detalha eventuais erros com botao Tentar novamente
- Assistente guiado de configuracao e instalacao de dependencias (com reinicio ao concluir)
- Novo modulo Download Web (yt-dlp) para YouTube, TikTok, LinkedIn e 1000+ sites
- Botao manual "Atualizacoes" para consultar GitHub Releases (nunca checa/instala sozinho)
- Idioma automatico conforme o sistema do Mac (Portugues, English, Espanol)
- Interface sempre clara (Light Mode fixo)
TXT

rm -f "$DMG_PATH"
hdiutil create \
    -volname "SOTAO57 macOS Tools" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

hdiutil verify "$DMG_PATH"
echo "DMG_OK: $DMG_PATH"
ls -lh "$DMG_PATH"
