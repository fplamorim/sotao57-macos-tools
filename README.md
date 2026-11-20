# SOTAO57 Basic Mac Tools

Suíte nativa para macOS (SwiftUI + Apple Vision + PDFKit + `ImageIO`) para converter e tratar ficheiros **100% localmente**, sem assinaturas, sem envio para a nuvem e salvando sempre na **mesma pasta do ficheiro original**.

Desenvolvido por **Fernando Amorim (SOTAO57)** sob a **Licença MIT**.

---

## Módulos incluídos

1. **Áudio** — `.mp3` (192 kbps ID3v2.3), `.m4a` (AAC Apple), `.opus` (Opus 48 kHz mono para WhatsApp Web / mensageiros), `.ogg`, `.wav` (PCM 16-bit), `.flac`
2. **Vídeo** — `.mp4` (H.264 + AAC com escolha de qualidade Padrão/Compacto), `.mov`, `.mkv`, `.webm`, `.gif` animado, e **Extrair Áudio (`.mp3`)**
3. **Texto & Documentos** — `.docx`, `.pdf`, `.txt`, `.rtf`, `.html`, `.md`, `.odt`
4. **Planilhas** — `.xlsx`, `.csv`, `.tsv`, `.json`, `.ods`, `.pdf`
5. **Imagens** — `.png`, `.jpg`, `.webp`, `.heic`, `.tiff`, `.pdf`
6. **PDF · OCR & Ferramentas**
   - **OCR em PDF (`-ocr.pdf`):** reconhece texto em PDFs escaneados via **Apple Vision Neural Engine** (Português / Inglês / Espanhol) e grava uma camada de texto invisível e selecionável sobre as páginas originais.
   - **Imagem(ns) → PDF com OCR (`-ocr.pdf`):** converte uma ou várias imagens (PNG, JPG, HEIC, TIFF, WebP) diretamente num único PDF pesquisável.
   - **Extrair texto OCR (`.txt`):** extrai o texto reconhecido de PDFs escaneados ou imagens para UTF-8.
   - **Desbloquear PDF com senha (`-desbloqueado.pdf`):** remove a proteção mediante a **senha informada pelo utilizador** para permitir edição noutro app. *(Para PDFs escaneados sem senha onde o texto é apenas imagem, utilize a opção «OCR em PDF».)*
   - **Juntar PDFs (`-unido.pdf`):** combina vários PDFs num só.
   - **Comprimir PDF (`-comprimido.pdf`):** reduz o tamanho do ficheiro para partilha rápida.

---

## Instalação rápida noutros Macs (`.dmg`)

1. Descarregue o ficheiro `SOTAO57-Basic-Mac-Tools-v1.0.0.dmg` em [GitHub Releases](https://github.com/fplamorim/sotao57-basic-mac-tools/releases).
2. Abra o `.dmg` e arraste **SOTAO57 Basic Mac Tools.app** para a pasta **Aplicações** (*Applications*).
3. Na primeira abertura, como a app tem assinatura local (*ad-hoc*), se o macOS Gatekeeper mostrar aviso, clique com o botão direito em **SOTAO57 Basic Mac Tools.app** → **Abrir** (ou **Definições do Sistema → Privacidade e Segurança → Abrir mesmo assim**).
4. *(Opcional)* Para ter conversão completa de vídeo, Opus/FLAC, Markdown, `.xlsx` avançado e desbloqueio/compressão vetorial de PDFs noutro Mac, corra o atalho `Instalar Dependencias Opcionais.command` incluído no `.dmg` ou execute no Terminal:
   ```bash
   brew install ffmpeg pandoc qpdf ghostscript webp
   brew install --cask libreoffice
   ```
   *(OCR com Apple Vision, imagens PNG/JPG/HEIC/TIFF/PDF, extração/junção de PDF e formatos áudio AAC/WAV nativos funcionam mesmo sem instalar extras.)*

---

## Compilar a partir do código-fonte

Requer Xcode Command Line Tools (`xcode-select --install`) no macOS 13+:

```bash
./scripts/build.sh
./scripts/build_dmg.sh
```

- O script `scripts/build.sh` compila para `/Applications/SOTAO57 Basic Mac Tools.app`.
- O script `scripts/build_dmg.sh` gera o instalador portátil em `dist/SOTAO57-Basic-Mac-Tools-v1.0.0.dmg`.

---

## Licença

MIT — veja [LICENSE](LICENSE). Copyright © 2026 Fernando Amorim (SOTAO57).
