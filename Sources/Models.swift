import Foundation

enum ToolCategory: String, CaseIterable, Identifiable {
    case audio
    case video
    case webDownload = "webdownload"
    case text
    case spreadsheet
    case image
    case pdf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .audio:
            return L10n.t("Áudio", en: "Audio", es: "Audio")
        case .video:
            return L10n.t("Vídeo", en: "Video", es: "Video")
        case .webDownload:
            return L10n.t("Download Web", en: "Web Download", es: "Descarga Web")
        case .text:
            return L10n.t("Texto & Documentos", en: "Text & Documents", es: "Texto y Documentos")
        case .spreadsheet:
            return L10n.t("Planilhas", en: "Spreadsheets", es: "Hojas de Cálculo")
        case .image:
            return L10n.t("Imagens", en: "Images", es: "Imágenes")
        case .pdf:
            return L10n.t("PDF · OCR & Desbloqueio", en: "PDF · OCR & Unlock", es: "PDF · OCR y Desbloqueo")
        }
    }

    var subtitle: String {
        switch self {
        case .audio:
            return "MP3, M4A, OPUS, OGG, WAV, FLAC"
        case .video:
            return L10n.t(
                "MP4, MOV, MKV, WebM, GIF e extrair MP3",
                en: "MP4, MOV, MKV, WebM, GIF & extract MP3",
                es: "MP4, MOV, MKV, WebM, GIF y extraer MP3"
            )
        case .webDownload:
            return L10n.t(
                "YouTube, TikTok, LinkedIn, Instagram, X e 1000+ sites",
                en: "YouTube, TikTok, LinkedIn, Instagram, X & 1000+ sites",
                es: "YouTube, TikTok, LinkedIn, Instagram, X y 1000+ sitios"
            )
        case .text:
            return "DOCX, PDF, TXT, RTF, HTML, Markdown, ODT"
        case .spreadsheet:
            return L10n.t(
                "XLSX, CSV, TSV, JSON, ODS e PDF",
                en: "XLSX, CSV, TSV, JSON, ODS & PDF",
                es: "XLSX, CSV, TSV, JSON, ODS y PDF"
            )
        case .image:
            return L10n.t(
                "PNG, JPG, WebP, HEIC, TIFF e PDF",
                en: "PNG, JPG, WebP, HEIC, TIFF & PDF",
                es: "PNG, JPG, WebP, HEIC, TIFF y PDF"
            )
        case .pdf:
            return L10n.t(
                "OCR nativo, Imagem→PDF OCR, desbloquear, juntar e comprimir",
                en: "Native OCR, Image→OCR PDF, unlock with password, merge & compress",
                es: "OCR nativo, Imagen→PDF OCR, desbloquear, unir y comprimir"
            )
        }
    }

    var symbol: String {
        switch self {
        case .audio: return "waveform"
        case .video: return "film.stack"
        case .webDownload: return "arrow.down.circle.fill"
        case .text: return "doc.text"
        case .spreadsheet: return "tablecells"
        case .image: return "photo.on.rectangle"
        case .pdf: return "doc.viewfinder"
        }
    }

    var acceptedExtensions: [String] {
        switch self {
        case .audio:
            return ["wav", "mp3", "m4a", "ogg", "opus", "flac", "aac", "aiff", "aif", "caf", "wma", "webm", "mp4", "mov"]
        case .video:
            return ["mp4", "mov", "mkv", "avi", "webm", "m4v", "ts", "flv", "wmv", "mpg", "mpeg", "gif"]
        case .webDownload:
            return []
        case .text:
            return ["docx", "doc", "odt", "rtf", "txt", "md", "markdown", "html", "htm", "pdf"]
        case .spreadsheet:
            return ["xlsx", "xls", "ods", "csv", "tsv", "json"]
        case .image:
            return ["png", "jpg", "jpeg", "webp", "heic", "heif", "tiff", "tif", "bmp", "gif"]
        case .pdf:
            return ["pdf", "png", "jpg", "jpeg", "webp", "heic", "heif", "tiff", "tif"]
        }
    }

    var dropHint: String {
        switch self {
        case .audio: return "WAV, MP3, M4A, OGG, OPUS, FLAC, MP4…"
        case .video: return "MP4, MOV, MKV, AVI, WebM, M4V…"
        case .webDownload: return "YouTube, TikTok, LinkedIn, Instagram, X, Vimeo…"
        case .text: return "DOCX, PDF, TXT, RTF, HTML, MD, ODT…"
        case .spreadsheet: return "XLSX, XLS, ODS, CSV, TSV, JSON…"
        case .image: return "PNG, JPG, WebP, HEIC, TIFF, BMP…"
        case .pdf:
            return L10n.t(
                "PDF (escaneado ou protegido) ou imagens…",
                en: "PDF (scanned or password-protected) or images…",
                es: "PDF (escaneado o protegido) o imágenes…"
            )
        }
    }

    var options: [ToolOption] {
        switch self {
        case .audio:
            return [
                ToolOption(
                    id: "mp3",
                    badge: ".mp3",
                    title: L10n.t("MP3 Universal", en: "Universal MP3", es: "MP3 Universal"),
                    subtitle: L10n.t("192 kbps · WhatsApp Web, podcasts e leitores", en: "192 kbps · WhatsApp Web, podcasts & players", es: "192 kbps · WhatsApp Web, podcasts y reproductores"),
                    outputExtension: "mp3"
                ),
                ToolOption(
                    id: "m4a",
                    badge: ".m4a",
                    title: "Apple AAC",
                    subtitle: L10n.t("192 kbps · iPhone, Mac e Gravador", en: "192 kbps · iPhone, Mac & Voice Memos", es: "192 kbps · iPhone, Mac y Notas de Voz"),
                    outputExtension: "m4a"
                ),
                ToolOption(
                    id: "opus",
                    badge: ".opus",
                    title: L10n.t("Opus Leve", en: "Compact Opus", es: "Opus Ligero"),
                    subtitle: L10n.t("48 kHz mono · compacto para mensageiros", en: "48 kHz mono · compact for messaging apps", es: "48 kHz mono · compacto para mensajería"),
                    outputExtension: "opus"
                ),
                ToolOption(
                    id: "ogg",
                    badge: ".ogg",
                    title: "Ogg Opus",
                    subtitle: L10n.t("48 kHz mono · Web e automações", en: "48 kHz mono · Web & automations", es: "48 kHz mono · Web y automatizaciones"),
                    outputExtension: "ogg"
                ),
                ToolOption(
                    id: "wav",
                    badge: ".wav",
                    title: L10n.t("WAV Estúdio", en: "Studio WAV", es: "WAV Estudio"),
                    subtitle: L10n.t("PCM 16-bit 44.1 kHz sem compressão", en: "PCM 16-bit 44.1 kHz uncompressed", es: "PCM 16-bit 44.1 kHz sin compresión"),
                    outputExtension: "wav"
                ),
                ToolOption(
                    id: "flac",
                    badge: ".flac",
                    title: "FLAC Lossless",
                    subtitle: L10n.t("Alta fidelidade sem perda de áudio", en: "High-fidelity lossless audio", es: "Alta fidelidad sin pérdida"),
                    outputExtension: "flac"
                ),
            ]
        case .video:
            return [
                ToolOption(
                    id: "mp4",
                    badge: ".mp4",
                    title: "MP4 H.264",
                    subtitle: L10n.t("Compatível com Web, WhatsApp, TV e Mac/PC", en: "Compatible with Web, WhatsApp, TV & Mac/PC", es: "Compatible con Web, WhatsApp, TV y Mac/PC"),
                    outputExtension: "mp4"
                ),
                ToolOption(
                    id: "mov",
                    badge: ".mov",
                    title: "QuickTime MOV",
                    subtitle: L10n.t("Edição no macOS (Final Cut / Premiere)", en: "macOS editing (Final Cut / Premiere)", es: "Edición en macOS (Final Cut / Premiere)"),
                    outputExtension: "mov"
                ),
                ToolOption(
                    id: "mkv",
                    badge: ".mkv",
                    title: "Matroska MKV",
                    subtitle: L10n.t("Contêiner flexível sem perda de faixas", en: "Flexible container with multiple tracks", es: "Contenedor flexible multipista"),
                    outputExtension: "mkv"
                ),
                ToolOption(
                    id: "webm",
                    badge: ".webm",
                    title: "WebM VP9",
                    subtitle: L10n.t("Leve para publicação na Web", en: "Lightweight for Web publishing", es: "Ligero para publicación Web"),
                    outputExtension: "webm"
                ),
                ToolOption(
                    id: "gif",
                    badge: ".gif",
                    title: L10n.t("GIF Animado", en: "Animated GIF", es: "GIF Animado"),
                    subtitle: L10n.t("12 fps · largura 640 px otimizado", en: "12 fps · optimized 640 px width", es: "12 fps · ancho 640 px optimizado"),
                    outputExtension: "gif"
                ),
                ToolOption(
                    id: "extract_mp3",
                    badge: "MP3",
                    title: L10n.t("Extrair Áudio", en: "Extract Audio", es: "Extraer Audio"),
                    subtitle: L10n.t("Salva apenas o áudio do vídeo em .mp3 (192k)", en: "Saves only the video's audio track as .mp3 (192k)", es: "Guarda solo el audio del video en .mp3 (192k)"),
                    outputExtension: "mp3"
                ),
            ]
        case .webDownload:
            return [
                ToolOption(
                    id: "mp4_best",
                    badge: "MP4 HD",
                    title: L10n.t("Vídeo MP4 (Melhor qualidade)", en: "MP4 Video (Best quality)", es: "Video MP4 (Mejor calidad)"),
                    subtitle: L10n.t("Baixa a maior resolução disponível com áudio AAC", en: "Downloads highest available resolution with AAC audio", es: "Descarga la mayor resolución disponible con audio AAC"),
                    outputExtension: "mp4"
                ),
                ToolOption(
                    id: "mp4_1080",
                    badge: "1080p",
                    title: L10n.t("Vídeo MP4 Full HD (até 1080p)", en: "Full HD MP4 Video (up to 1080p)", es: "Video MP4 Full HD (hasta 1080p)"),
                    subtitle: L10n.t("Ótima nitidez e compatível com edição e apresentações", en: "Sharp quality for editing and presentations", es: "Gran nitidez para edición y presentaciones"),
                    outputExtension: "mp4"
                ),
                ToolOption(
                    id: "mp4_720",
                    badge: "720p",
                    title: L10n.t("Vídeo MP4 Compacto (até 720p)", en: "Compact MP4 Video (up to 720p)", es: "Video MP4 Compacto (hasta 720p)"),
                    subtitle: L10n.t("Arquivo mais leve · ideal para WhatsApp e celular", en: "Smaller file · ideal for WhatsApp & mobile", es: "Archivo más ligero · ideal para WhatsApp y móvil"),
                    outputExtension: "mp4"
                ),
                ToolOption(
                    id: "audio_mp3",
                    badge: ".mp3",
                    title: L10n.t("Extrair Áudio MP3", en: "Extract MP3 Audio", es: "Extraer Audio MP3"),
                    subtitle: L10n.t("Salva somente o áudio do link em MP3 192 kbps", en: "Saves audio only from the link as 192 kbps MP3", es: "Guarda solo el audio del enlace en MP3 192 kbps"),
                    outputExtension: "mp3"
                ),
                ToolOption(
                    id: "audio_m4a",
                    badge: ".m4a",
                    title: L10n.t("Extrair Áudio Apple (.m4a)", en: "Extract Apple Audio (.m4a)", es: "Extraer Audio Apple (.m4a)"),
                    subtitle: L10n.t("Áudio AAC nativo para Mac, iPhone e iPad", en: "Native AAC audio for Mac, iPhone & iPad", es: "Audio AAC nativo para Mac, iPhone y iPad"),
                    outputExtension: "m4a"
                ),
            ]
        case .text:
            return [
                ToolOption(
                    id: "docx",
                    badge: ".docx",
                    title: "Microsoft Word",
                    subtitle: L10n.t("Documento editável (.docx)", en: "Editable document (.docx)", es: "Documento editable (.docx)"),
                    outputExtension: "docx"
                ),
                ToolOption(
                    id: "pdf",
                    badge: ".pdf",
                    title: L10n.t("PDF Documento", en: "PDF Document", es: "Documento PDF"),
                    subtitle: L10n.t("Layout fixo pronto para envio/impressão", en: "Fixed layout ready to share or print", es: "Diseño fijo listo para enviar o imprimir"),
                    outputExtension: "pdf"
                ),
                ToolOption(
                    id: "txt",
                    badge: ".txt",
                    title: L10n.t("Texto Simples", en: "Plain Text", es: "Texto Plano"),
                    subtitle: L10n.t("UTF-8 limpo (extrai texto de PDF também)", en: "Clean UTF-8 (extracts text from PDFs too)", es: "UTF-8 limpio (extrae texto de PDF también)"),
                    outputExtension: "txt"
                ),
                ToolOption(
                    id: "rtf",
                    badge: ".rtf",
                    title: "Rich Text (RTF)",
                    subtitle: L10n.t("Compatível com TextEdit e Word", en: "Compatible with TextEdit & Word", es: "Compatible con TextEdit y Word"),
                    outputExtension: "rtf"
                ),
                ToolOption(
                    id: "html",
                    badge: ".html",
                    title: L10n.t("Página HTML", en: "HTML Page", es: "Página HTML"),
                    subtitle: L10n.t("Documento Web limpo em UTF-8", en: "Clean UTF-8 Web document", es: "Documento Web limpio en UTF-8"),
                    outputExtension: "html"
                ),
                ToolOption(
                    id: "md",
                    badge: ".md",
                    title: "Markdown",
                    subtitle: L10n.t("Para Obsidian, GitHub e editores modernos", en: "For Obsidian, GitHub & modern editors", es: "Para Obsidian, GitHub y editores modernos"),
                    outputExtension: "md"
                ),
                ToolOption(
                    id: "odt",
                    badge: ".odt",
                    title: "OpenDocument",
                    subtitle: L10n.t("Formato aberto LibreOffice / Writer", en: "Open LibreOffice / Writer format", es: "Formato abierto LibreOffice / Writer"),
                    outputExtension: "odt"
                ),
            ]
        case .spreadsheet:
            return [
                ToolOption(
                    id: "xlsx",
                    badge: ".xlsx",
                    title: "Excel (.xlsx)",
                    subtitle: L10n.t("Planilha moderna Microsoft Excel / Numbers", en: "Modern Microsoft Excel / Numbers workbook", es: "Hoja de cálculo Microsoft Excel / Numbers"),
                    outputExtension: "xlsx"
                ),
                ToolOption(
                    id: "csv",
                    badge: ".csv",
                    title: "CSV (UTF-8)",
                    subtitle: L10n.t("Valores separados por vírgula para scripts e BI", en: "Comma-separated values for scripts & BI", es: "Valores separados por comas para scripts y BI"),
                    outputExtension: "csv"
                ),
                ToolOption(
                    id: "tsv",
                    badge: ".tsv",
                    title: L10n.t("TSV (Tabulação)", en: "TSV (Tab-separated)", es: "TSV (Tabulación)"),
                    subtitle: L10n.t("Valores separados por TAB sem conflito de vírgula", en: "Tab-separated values without comma conflicts", es: "Valores separados por tabulador"),
                    outputExtension: "tsv"
                ),
                ToolOption(
                    id: "json",
                    badge: ".json",
                    title: L10n.t("JSON Estruturado", en: "Structured JSON", es: "JSON Estructurado"),
                    subtitle: L10n.t("Lista de objetos JSON pronta para APIs e Python", en: "JSON object list ready for APIs & Python", es: "Lista de objetos JSON para APIs y Python"),
                    outputExtension: "json"
                ),
                ToolOption(
                    id: "ods",
                    badge: ".ods",
                    title: "OpenDocument (.ods)",
                    subtitle: L10n.t("Planilha aberta LibreOffice Calc", en: "Open LibreOffice Calc spreadsheet", es: "Hoja abierta LibreOffice Calc"),
                    outputExtension: "ods"
                ),
                ToolOption(
                    id: "pdf",
                    badge: ".pdf",
                    title: L10n.t("Exportar PDF", en: "Export PDF", es: "Exportar PDF"),
                    subtitle: L10n.t("Tabela formatada pronta para partilha", en: "Formatted table ready to share", es: "Tabla formateada lista para compartir"),
                    outputExtension: "pdf"
                ),
            ]
        case .image:
            return [
                ToolOption(
                    id: "png",
                    badge: ".png",
                    title: L10n.t("PNG Sem Perda", en: "Lossless PNG", es: "PNG Sin Pérdida"),
                    subtitle: L10n.t("Com transparência · capturas e gráficos", en: "With transparency · screenshots & graphics", es: "Con transparencia · capturas y gráficos"),
                    outputExtension: "png"
                ),
                ToolOption(
                    id: "jpg",
                    badge: ".jpg",
                    title: L10n.t("JPEG Compacto", en: "Compact JPEG", es: "JPEG Compacto"),
                    subtitle: L10n.t("Qualidade 90% · leve para Web e envio rápido", en: "90% quality · lightweight for Web & sharing", es: "Calidad 90% · ligero para Web y envío rápido"),
                    outputExtension: "jpg"
                ),
                ToolOption(
                    id: "webp",
                    badge: ".webp",
                    title: L10n.t("WebP Moderno", en: "Modern WebP", es: "WebP Moderno"),
                    subtitle: L10n.t("Ideal para sites (leve e nítido)", en: "Ideal for websites (compact & crisp)", es: "Ideal para sitios Web (ligero y nítido)"),
                    outputExtension: "webp"
                ),
                ToolOption(
                    id: "heic",
                    badge: ".heic",
                    title: "Apple HEIC",
                    subtitle: L10n.t("Alta eficiência nativa Apple", en: "Apple native high-efficiency image", es: "Alta eficiencia nativa de Apple"),
                    outputExtension: "heic"
                ),
                ToolOption(
                    id: "tiff",
                    badge: ".tiff",
                    title: L10n.t("TIFF Arquivo", en: "Archival TIFF", es: "TIFF Archivo"),
                    subtitle: L10n.t("Alta resolução sem perda para impressão", en: "High-resolution lossless print format", es: "Alta resolución sin pérdida para impresión"),
                    outputExtension: "tiff"
                ),
                ToolOption(
                    id: "pdf",
                    badge: ".pdf",
                    title: L10n.t("Converter em PDF", en: "Convert to PDF", es: "Convertir a PDF"),
                    subtitle: L10n.t("Transforma a(s) imagem(ns) num arquivo PDF", en: "Turns selected image(s) into a PDF document", es: "Convierte las imágenes en un documento PDF"),
                    outputExtension: "pdf",
                    supportsMultipleInputs: true
                ),
            ]
        case .pdf:
            return [
                ToolOption(
                    id: "ocr_pdf",
                    badge: "OCR PDF",
                    title: L10n.t("OCR em PDF (Pesquisável)", en: "PDF OCR (Searchable)", es: "OCR en PDF (Buscable)"),
                    subtitle: L10n.t("Apple Vision: torna PDFs escaneados editáveis/selecionáveis", en: "Apple Vision: makes scanned PDFs selectable & searchable", es: "Apple Vision: vuelve editables/seleccionables los PDF escaneados"),
                    outputExtension: "pdf",
                    fileSuffix: "-ocr",
                    usesOCR: true
                ),
                ToolOption(
                    id: "img_ocr_pdf",
                    badge: "IMG→OCR",
                    title: L10n.t("Imagem(ns) → PDF com OCR", en: "Image(s) → OCR PDF", es: "Imagen(es) → PDF con OCR"),
                    subtitle: L10n.t("Converte PNG/JPG/HEIC em PDF já pesquisável", en: "Converts PNG/JPG/HEIC straight into a searchable PDF", es: "Convierte PNG/JPG/HEIC directamente en un PDF buscable"),
                    outputExtension: "pdf",
                    fileSuffix: "-ocr",
                    usesOCR: true,
                    supportsMultipleInputs: true
                ),
                ToolOption(
                    id: "ocr_txt",
                    badge: "OCR TXT",
                    title: L10n.t("Extrair Texto OCR (.txt)", en: "Extract OCR Text (.txt)", es: "Extraer Texto OCR (.txt)"),
                    subtitle: L10n.t("Extrai todo o texto de PDF ou imagem para UTF-8", en: "Extracts all text from a PDF or image to UTF-8", es: "Extrae todo el texto de PDF o imagen a UTF-8"),
                    outputExtension: "txt",
                    fileSuffix: "-ocr",
                    usesOCR: true
                ),
                ToolOption(
                    id: "unlock",
                    badge: L10n.t("ABRIR", en: "UNLOCK", es: "ABRIR"),
                    title: L10n.t("Desbloquear PDF (com senha)", en: "Unlock PDF (with password)", es: "Desbloquear PDF (con contraseña)"),
                    subtitle: L10n.t("Remove proteção por senha para permitir edição", en: "Removes password protection to allow editing", es: "Elimina protección por contraseña para permitir edición"),
                    outputExtension: "pdf",
                    fileSuffix: L10n.t("-desbloqueado", en: "-unlocked", es: "-desbloqueado"),
                    requiresPassword: true
                ),
                ToolOption(
                    id: "merge",
                    badge: L10n.t("JUNTAR", en: "MERGE", es: "UNIR"),
                    title: L10n.t("Juntar PDFs", en: "Merge PDFs", es: "Unir PDFs"),
                    subtitle: L10n.t("Combina 2 ou mais PDFs na ordem selecionada", en: "Combines 2 or more PDFs in selected order", es: "Combina 2 o más PDFs en el orden seleccionado"),
                    outputExtension: "pdf",
                    fileSuffix: L10n.t("-unido", en: "-merged", es: "-unido"),
                    supportsMultipleInputs: true
                ),
                ToolOption(
                    id: "compress",
                    badge: L10n.t("LEVE", en: "SHRINK", es: "LIGERO"),
                    title: L10n.t("Comprimir PDF", en: "Compress PDF", es: "Comprimir PDF"),
                    subtitle: L10n.t("Reduz tamanho de PDFs grandes para envio", en: "Reduces size of large PDFs for sharing", es: "Reduce el tamaño de PDFs grandes para enviar"),
                    outputExtension: "pdf",
                    fileSuffix: L10n.t("-comprimido", en: "-compressed", es: "-comprimido")
                ),
            ]
        }
    }
}

struct ToolOption: Identifiable, Hashable {
    let id: String
    let badge: String
    let title: String
    let subtitle: String
    let outputExtension: String
    var fileSuffix: String = ""
    var requiresPassword: Bool = false
    var usesOCR: Bool = false
    var supportsMultipleInputs: Bool = false

    func outputURL(for primaryInput: URL) -> URL {
        let baseURL = primaryInput.standardizedFileURL
        let folder = baseURL.deletingLastPathComponent()
        let stem = baseURL.deletingPathExtension().lastPathComponent
        return folder
            .appendingPathComponent("\(stem)\(fileSuffix)")
            .appendingPathExtension(outputExtension)
            .standardizedFileURL
    }
}

enum OCRLanguagePreset: String, CaseIterable, Identifiable {
    case ptEn = "pt_en"
    case pt = "pt"
    case en = "en"
    case es = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ptEn: return L10n.t("Português + Inglês", en: "Portuguese + English", es: "Portugués + Inglés")
        case .pt: return L10n.t("Português", en: "Portuguese", es: "Portugués")
        case .en: return L10n.t("Inglês", en: "English", es: "Inglés")
        case .es: return L10n.t("Espanhol", en: "Spanish", es: "Español")
        }
    }

    static var defaultForSystem: OCRLanguagePreset {
        switch AppLanguage.current {
        case .pt: return .ptEn
        case .en: return .en
        case .es: return .es
        }
    }

    var codes: [String] {
        switch self {
        case .ptEn: return ["pt-BR", "pt-PT", "en-US"]
        case .pt: return ["pt-BR", "pt-PT"]
        case .en: return ["en-US"]
        case .es: return ["es-ES"]
        }
    }
}

enum VideoQuality: String, CaseIterable, Identifiable {
    case balanced = "balanced"
    case compact = "compact"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .balanced:
            return L10n.t("Padrão (Alta qualidade)", en: "Standard (High quality)", es: "Estándar (Alta calidad)")
        case .compact:
            return L10n.t("Compacto (WhatsApp / Web)", en: "Compact (WhatsApp / Web)", es: "Compacto (WhatsApp / Web)")
        }
    }

    var crf: String {
        switch self {
        case .balanced: return "22"
        case .compact: return "28"
        }
    }
}

enum ToolError: LocalizedError {
    case emptyInput
    case inputMissing(String)
    case sameOutputPath
    case missingTool(String, String)
    case commandFailed(String)
    case invalidInput(String)
    case passwordRequired
    case unlockFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return L10n.t(
                "Selecione pelo menos um arquivo.",
                en: "Please select at least one file.",
                es: "Seleccione al menos un archivo."
            )
        case .inputMissing(let path):
            return L10n.t(
                "Arquivo não encontrado: \(path)",
                en: "File not found: \(path)",
                es: "Archivo no encontrado: \(path)"
            )
        case .sameOutputPath:
            return L10n.t(
                "O arquivo já está nesse formato. Escolha outra extensão.",
                en: "The file is already in that format. Choose a different output.",
                es: "El archivo ya está en ese formato. Elige otra extensión."
            )
        case .missingTool(let name, let brewHint):
            return L10n.t(
                "Dependência '\(name)' não encontrada neste Mac. Use o Assistente no Início ou instale via Terminal: \(brewHint)",
                en: "Tool '\(name)' is not installed on this Mac. Use Setup Wizard on Home or run: \(brewHint)",
                es: "Herramienta '\(name)' no encontrada en este Mac. Usa el Asistente en Inicio o instala con: \(brewHint)"
            )
        case .commandFailed(let detail):
            return detail.isEmpty
                ? L10n.t("Erro durante a operação.", en: "Operation failed.", es: "Error durante la operación.")
                : detail
        case .invalidInput(let msg):
            return msg
        case .passwordRequired:
            return L10n.t(
                "Informe a senha atual do PDF para desbloqueá-lo.",
                en: "Enter the current PDF password to unlock it.",
                es: "Ingresa la contraseña actual del PDF para desbloquearlo."
            )
        case .unlockFailed(let msg):
            return msg
        }
    }
}

struct DependencyStatus: Identifiable, Hashable {
    let id: String
    let name: String
    let purpose: String
    let path: String?
    let installHint: String
    let isNative: Bool
    let brewPackage: String?
    let isCask: Bool
    let defaultSelected: Bool

    var isInstalled: Bool { path != nil }
}

enum SetupWizardStep: Int, CaseIterable {
    case check = 0
    case selectAndAuth = 1
    case installing = 2
    case done = 3
}

enum PackageInstallState: Equatable {
    case pending
    case installing
    case installed
    case failed(String)
}
