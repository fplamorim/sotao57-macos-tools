import Foundation

enum ToolCategory: String, CaseIterable, Identifiable {
    case audio
    case video
    case text
    case spreadsheet
    case image
    case pdf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .audio: return "Áudio"
        case .video: return "Vídeo"
        case .text: return "Texto & Documentos"
        case .spreadsheet: return "Planilhas"
        case .image: return "Imagens"
        case .pdf: return "PDF · OCR & Desbloqueio"
        }
    }

    var subtitle: String {
        switch self {
        case .audio: return "MP3, M4A, OPUS, OGG, WAV, FLAC"
        case .video: return "MP4, MOV, MKV, WebM, GIF e extrair MP3"
        case .text: return "DOCX, PDF, TXT, RTF, HTML, Markdown, ODT"
        case .spreadsheet: return "XLSX, CSV, TSV, JSON, ODS e PDF"
        case .image: return "PNG, JPG, WebP, HEIC, TIFF e PDF"
        case .pdf: return "OCR nativo, Imagem→PDF OCR, desbloquear, juntar"
        }
    }

    var symbol: String {
        switch self {
        case .audio: return "waveform"
        case .video: return "film.stack"
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
        case .text: return "DOCX, PDF, TXT, RTF, HTML, MD, ODT…"
        case .spreadsheet: return "XLSX, XLS, ODS, CSV, TSV, JSON…"
        case .image: return "PNG, JPG, WebP, HEIC, TIFF, BMP…"
        case .pdf: return "PDF (escaneado ou protegido) ou imagens…"
        }
    }

    var options: [ToolOption] {
        switch self {
        case .audio:
            return [
                ToolOption(id: "mp3", badge: ".mp3", title: "MP3 Universal", subtitle: "192 kbps · WhatsApp Web, podcasts e leitores", outputExtension: "mp3"),
                ToolOption(id: "m4a", badge: ".m4a", title: "Apple AAC", subtitle: "192 kbps · iPhone, Mac e Gravador", outputExtension: "m4a"),
                ToolOption(id: "opus", badge: ".opus", title: "Opus Leve", subtitle: "48 kHz mono · compacto para mensageiros", outputExtension: "opus"),
                ToolOption(id: "ogg", badge: ".ogg", title: "Ogg Opus", subtitle: "48 kHz mono · Web e automações", outputExtension: "ogg"),
                ToolOption(id: "wav", badge: ".wav", title: "WAV Estúdio", subtitle: "PCM 16-bit 44.1 kHz sem compressão", outputExtension: "wav"),
                ToolOption(id: "flac", badge: ".flac", title: "FLAC Lossless", subtitle: "Alta fidelidade sem perda de áudio", outputExtension: "flac"),
            ]
        case .video:
            return [
                ToolOption(id: "mp4", badge: ".mp4", title: "MP4 H.264", subtitle: "Compatível com Web, WhatsApp, TV e Mac/PC", outputExtension: "mp4"),
                ToolOption(id: "mov", badge: ".mov", title: "QuickTime MOV", subtitle: "Edição no macOS (Final Cut / Premiere)", outputExtension: "mov"),
                ToolOption(id: "mkv", badge: ".mkv", title: "Matroska MKV", subtitle: "Contêiner flexível sem perda de faixas", outputExtension: "mkv"),
                ToolOption(id: "webm", badge: ".webm", title: "WebM VP9", subtitle: "Leve para publicação na Web", outputExtension: "webm"),
                ToolOption(id: "gif", badge: ".gif", title: "GIF Animado", subtitle: "12 fps · largura 640 px otimizado", outputExtension: "gif"),
                ToolOption(id: "extract_mp3", badge: "MP3", title: "Extrair Áudio", subtitle: "Salva apenas o áudio do vídeo em .mp3 (192k)", outputExtension: "mp3"),
            ]
        case .text:
            return [
                ToolOption(id: "docx", badge: ".docx", title: "Microsoft Word", subtitle: "Documento editável (.docx)", outputExtension: "docx"),
                ToolOption(id: "pdf", badge: ".pdf", title: "PDF Documento", subtitle: "Layout fixo pronto para envio/impressão", outputExtension: "pdf"),
                ToolOption(id: "txt", badge: ".txt", title: "Texto Simples", subtitle: "UTF-8 limpo (extrai texto de PDF também)", outputExtension: "txt"),
                ToolOption(id: "rtf", badge: ".rtf", title: "Rich Text (RTF)", subtitle: "Compatível com TextEdit e Word", outputExtension: "rtf"),
                ToolOption(id: "html", badge: ".html", title: "Página HTML", subtitle: "Documento Web limpo em UTF-8", outputExtension: "html"),
                ToolOption(id: "md", badge: ".md", title: "Markdown", subtitle: "Para Obsidian, GitHub e editores modernos", outputExtension: "md"),
                ToolOption(id: "odt", badge: ".odt", title: "OpenDocument", subtitle: "Formato aberto LibreOffice / Writer", outputExtension: "odt"),
            ]
        case .spreadsheet:
            return [
                ToolOption(id: "xlsx", badge: ".xlsx", title: "Excel (.xlsx)", subtitle: "Planilha moderna Microsoft Excel / Numbers", outputExtension: "xlsx"),
                ToolOption(id: "csv", badge: ".csv", title: "CSV (UTF-8)", subtitle: "Valores separados por vírgula para scripts e BI", outputExtension: "csv"),
                ToolOption(id: "tsv", badge: ".tsv", title: "TSV (Tabulação)", subtitle: "Valores separados por TAB sem conflito de vírgula", outputExtension: "tsv"),
                ToolOption(id: "json", badge: ".json", title: "JSON Estruturado", subtitle: "Lista de objetos JSON pronta para APIs e Python", outputExtension: "json"),
                ToolOption(id: "ods", badge: ".ods", title: "OpenDocument (.ods)", subtitle: "Planilha aberta LibreOffice Calc", outputExtension: "ods"),
                ToolOption(id: "pdf", badge: ".pdf", title: "Exportar PDF", subtitle: "Tabela formatada pronta para partilha", outputExtension: "pdf"),
            ]
        case .image:
            return [
                ToolOption(id: "png", badge: ".png", title: "PNG Sem Perda", subtitle: "Com transparência · capturas e gráficos", outputExtension: "png"),
                ToolOption(id: "jpg", badge: ".jpg", title: "JPEG Compacto", subtitle: "Qualidade 90% · leve para Web e envio rápido", outputExtension: "jpg"),
                ToolOption(id: "webp", badge: ".webp", title: "WebP Moderno", subtitle: "Ideal para sites (leve e nítido)", outputExtension: "webp"),
                ToolOption(id: "heic", badge: ".heic", title: "Apple HEIC", subtitle: "Alta eficiência nativa Apple", outputExtension: "heic"),
                ToolOption(id: "tiff", badge: ".tiff", title: "TIFF Arquivo", subtitle: "Alta resolução sem perda para impressão", outputExtension: "tiff"),
                ToolOption(id: "pdf", badge: ".pdf", title: "Converter em PDF", subtitle: "Transforma a(s) imagem(ns) num ficheiro PDF", outputExtension: "pdf", supportsMultipleInputs: true),
            ]
        case .pdf:
            return [
                ToolOption(id: "ocr_pdf", badge: "OCR PDF", title: "OCR em PDF (Pesquisável)", subtitle: "Apple Vision: torna PDFs escaneados editáveis/selecionáveis", outputExtension: "pdf", fileSuffix: "-ocr", usesOCR: true),
                ToolOption(id: "img_ocr_pdf", badge: "IMG→OCR", title: "Imagem(ns) → PDF com OCR", subtitle: "Converte PNG/JPG/HEIC em PDF já pesquisável", outputExtension: "pdf", fileSuffix: "-ocr", usesOCR: true, supportsMultipleInputs: true),
                ToolOption(id: "ocr_txt", badge: "OCR TXT", title: "Extrair Texto OCR (.txt)", subtitle: "Extrai todo o texto de PDF ou imagem para UTF-8", outputExtension: "txt", fileSuffix: "-ocr", usesOCR: true),
                ToolOption(id: "unlock", badge: "ABRIR", title: "Desbloquear PDF (com senha)", subtitle: "Remove proteção por senha para permitir edição", outputExtension: "pdf", fileSuffix: "-desbloqueado", requiresPassword: true),
                ToolOption(id: "merge", badge: "JUNTAR", title: "Juntar PDFs", subtitle: "Combina 2 ou mais PDFs na ordem selecionada", outputExtension: "pdf", fileSuffix: "-unido", supportsMultipleInputs: true),
                ToolOption(id: "compress", badge: "LEVE", title: "Comprimir PDF", subtitle: "Reduz tamanho de PDFs grandes para envio", outputExtension: "pdf", fileSuffix: "-comprimido"),
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
    case ptEn = "Português + Inglês"
    case pt = "Português"
    case en = "Inglês"
    case es = "Espanhol"

    var id: String { rawValue }

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
    case balanced = "Padrão (Alta qualidade)"
    case compact = "Compacto (WhatsApp / Web)"

    var id: String { rawValue }

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
            return "Selecione pelo menos um ficheiro."
        case .inputMissing(let path):
            return "Ficheiro não encontrado: \(path)"
        case .sameOutputPath:
            return "O ficheiro já está nesse formato. Escolha outra extensão."
        case .missingTool(let name, let brewHint):
            return "Ferramenta '\(name)' não encontrada neste Mac. Instale via Terminal: \(brewHint)"
        case .commandFailed(let detail):
            return detail.isEmpty ? "Erro durante a conversão." : detail
        case .invalidInput(let msg):
            return msg
        case .passwordRequired:
            return "Informe a senha atual do PDF para desbloqueá-lo."
        case .unlockFailed(let msg):
            return msg
        }
    }
}

struct DependencyStatus: Identifiable {
    let id: String
    let name: String
    let purpose: String
    let path: String?
    let installHint: String

    var isInstalled: Bool { path != nil }
}
