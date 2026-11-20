# SOTAO57 macOS Tools

Suíte utilitária nativa para macOS (SwiftUI + Apple Vision + PDFKit + `ImageIO`) para converter ficheiros, baixar vídeos/áudios públicos da Web, executar OCR pesquisável em PDFs e desbloquear PDFs protegidos — **sem assinaturas**, com interface **sempre clara** e adaptação automática ao **idioma do sistema** (Português, English e Español).

Desenvolvido por **Fernando Amorim (SOTAO57)** sob a **Licença MIT**.

---

## Módulos incluídos (v1.1.1)

1. **Áudio** — `.mp3` (192 kbps ID3v2.3), `.m4a` (AAC Apple), `.opus` (Opus 48 kHz mono para WhatsApp Web / mensageiros), `.ogg`, `.wav` (PCM 16-bit), `.flac`
2. **Vídeo** — `.mp4` (H.264 + AAC com escolha de qualidade Padrão/Compacto), `.mov`, `.mkv`, `.webm`, `.gif` animado, e **Extrair Áudio (`.mp3`)**
3. **Download Web (`yt-dlp`)** — cola o link público (YouTube, TikTok, LinkedIn, Instagram, X, Vimeo e centenas de outros sites), escolhe **MP4 (Melhor qualidade / 1080p / 720p)** ou **Extrair Áudio (`.mp3` / `.m4a`)** com barra de progresso ao vivo e escolha da pasta de destino
4. **Texto & Documentos** — `.docx`, `.pdf`, `.txt`, `.rtf`, `.html`, `.md`, `.odt`
5. **Planilhas** — `.xlsx`, `.csv`, `.tsv`, `.json`, `.ods`, `.pdf`
6. **Imagens** — `.png`, `.jpg`, `.webp`, `.heic`, `.tiff`, `.pdf`
7. **PDF · OCR & Desbloqueio**
   - **OCR em PDF (`-ocr.pdf`):** reconhece texto em PDFs escaneados via **Apple Vision Neural Engine** e grava uma camada de texto invisível e selecionável sobre as páginas originais.
   - **Imagem(ns) → PDF com OCR (`-ocr.pdf`):** converte PNG/JPG/HEIC/TIFF/WebP diretamente num único PDF pesquisável.
   - **Extrair texto OCR (`.txt`):** extrai o texto reconhecido de PDFs escaneados ou imagens para UTF-8.
   - **Desbloquear PDF com senha (`-desbloqueado.pdf` / `-unlocked.pdf`):** remove a proteção mediante a **senha informada pelo utilizador** para permitir edição noutro app.
   - **Juntar PDFs (`-unido.pdf` / `-merged.pdf`):** combina vários PDFs num só.
   - **Comprimir PDF (`-comprimido.pdf` / `-compressed.pdf`):** reduz o tamanho do ficheiro para partilha rápida.

---

## Assistente guiado, idioma e atualizações manuais

- **Assistente de Dependências (na primeira abertura e no botão *Dependências*):** verifica o Homebrew e os motores opcionais (`ffmpeg`, `yt-dlp`, `pandoc`, `qpdf`, `ghostscript`, `webp`, `libreoffice`), solicita autorização nativa ao macOS (com janela de senha quando necessário), exibe barras de progresso durante a instalação e reinicia o app ao concluir.
- **Checador Manual de Updates:** botão **Atualizações** na barra superior para consultar [GitHub Releases](https://github.com/fplamorim/sotao57-macos-tools/releases) somente quando clicado — nunca verifica nem instala atualizações automaticamente.
- **Idioma automático do sistema:** segue automaticamente o idioma principal do macOS (Português, English ou Español).
- **Tema claro fixo:** interface sempre em modo claro (Aqua/Light) para leitura consistente.

---

## Instalação rápida noutros Macs (`.dmg`)

1. Descarregue `SOTAO57-macOS-Tools-v1.1.1.dmg` em [GitHub Releases](https://github.com/fplamorim/sotao57-macos-tools/releases).
2. Abra o `.dmg` e arraste **SOTAO57 macOS Tools.app** para **Applications** (*Aplicações*).
3. Se o macOS Gatekeeper mostrar aviso por assinatura local (*ad-hoc*), clique com o botão direito em **SOTAO57 macOS Tools.app** → **Abrir** (ou **Definições do Sistema → Privacidade e Segurança → Abrir mesmo assim**).
4. Ao abrir o app, siga o **Assistente integrado** (ou, se preferir via Terminal, execute `brew install ffmpeg yt-dlp pandoc qpdf ghostscript webp` e opcionalmente `brew install --cask libreoffice`).

---

## Compilar a partir do código-fonte

Requer Xcode Command Line Tools (`xcode-select --install`) no macOS 13+:

```bash
./scripts/build.sh
./scripts/build_dmg.sh
```

- `scripts/build.sh` compila o binário Universal (`arm64` + `x86_64`) em `/Applications/SOTAO57 macOS Tools.app`.
- `scripts/build_dmg.sh` gera o instalador portátil em `dist/SOTAO57-macOS-Tools-v1.1.1.dmg`.

---

## Licença

MIT — veja [LICENSE](LICENSE). Copyright © 2026 Fernando Amorim (SOTAO57).
