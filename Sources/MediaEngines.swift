import AppKit
import CoreGraphics
import Foundation
import ImageIO
import PDFKit
import UniformTypeIdentifiers

enum MediaEngines {
    // MARK: - Audio

    static func convertAudio(inputURL: URL, option: ToolOption) -> Result<URL, Error> {
        let cleanInput = inputURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: cleanInput.path) else {
            return .failure(ToolError.inputMissing(cleanInput.path))
        }
        let outputURL = option.outputURL(for: cleanInput)
        if cleanInput == outputURL {
            return .failure(ToolError.sameOutputPath)
        }

        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-tmp-\(UUID().uuidString).\(option.outputExtension)")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        if let ffmpeg = ShellRunner.findExecutable(["ffmpeg"]) {
            var args = ["-y", "-nostdin", "-hide_banner", "-loglevel", "error", "-i", cleanInput.path, "-vn"]
            switch option.id {
            case "mp3":
                args += ["-ar", "44100", "-codec:a", "libmp3lame", "-b:a", "192k", "-write_id3v2", "1", "-id3v2_version", "3", tempURL.path]
            case "m4a":
                args += ["-ar", "44100", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", tempURL.path]
            case "opus", "ogg":
                args += ["-ar", "48000", "-ac", "1", "-c:a", "libopus", "-b:a", "32k", "-application", "voip", "-f", "ogg", tempURL.path]
            case "wav":
                args += ["-c:a", "pcm_s16le", "-ar", "44100", tempURL.path]
            case "flac":
                args += ["-c:a", "flac", tempURL.path]
            default:
                return .failure(ToolError.invalidInput("Formato de áudio inválido: \(option.id)"))
            }

            let res = ShellRunner.run(executable: ffmpeg, arguments: args, timeout: 600)
            guard res.status == 0, FileManager.default.fileExists(atPath: tempURL.path) else {
                return .failure(ToolError.commandFailed(res.stderr))
            }
            do {
                try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                return .success(outputURL)
            } catch {
                return .failure(error)
            }
        }

        // Native macOS fallback when ffmpeg is absent on another Mac
        if (option.id == "m4a" || option.id == "wav"), let afconvert = ShellRunner.findExecutable(["afconvert"]) {
            let args: [String] = option.id == "m4a"
                ? ["-f", "m4af", "-d", "aac", "-b", "192000", cleanInput.path, tempURL.path]
                : ["-f", "WAVE", "-d", "LEI16@44100", cleanInput.path, tempURL.path]
            let res = ShellRunner.run(executable: afconvert, arguments: args, timeout: 300)
            guard res.status == 0, FileManager.default.fileExists(atPath: tempURL.path) else {
                return .failure(ToolError.commandFailed(res.stderr))
            }
            do {
                try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                return .success(outputURL)
            } catch {
                return .failure(error)
            }
        }

        return .failure(ToolError.missingTool("ffmpeg", "brew install ffmpeg"))
    }

    // MARK: - Video

    static func convertVideo(inputURL: URL, option: ToolOption, quality: VideoQuality) -> Result<URL, Error> {
        let cleanInput = inputURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: cleanInput.path) else {
            return .failure(ToolError.inputMissing(cleanInput.path))
        }
        let outputURL = option.outputURL(for: cleanInput)
        if cleanInput == outputURL {
            return .failure(ToolError.sameOutputPath)
        }
        guard let ffmpeg = ShellRunner.findExecutable(["ffmpeg"]) else {
            return .failure(ToolError.missingTool("ffmpeg", "brew install ffmpeg"))
        }

        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-tmp-\(UUID().uuidString).\(option.outputExtension)")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var args = ["-y", "-nostdin", "-hide_banner", "-loglevel", "error", "-i", cleanInput.path]
        switch option.id {
        case "mp4":
            args += ["-c:v", "libx264", "-preset", "medium", "-crf", quality.crf, "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", tempURL.path]
        case "mov":
            args += ["-c:v", "libx264", "-preset", "medium", "-crf", quality.crf, "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", tempURL.path]
        case "mkv":
            args += ["-c:v", "libx264", "-preset", "medium", "-crf", quality.crf, "-c:a", "aac", "-b:a", "160k", tempURL.path]
        case "webm":
            args += ["-c:v", "libvpx-vp9", "-crf", quality == .balanced ? "30" : "35", "-b:v", "0", "-c:a", "libopus", "-b:a", "128k", tempURL.path]
        case "gif":
            args += ["-vf", "fps=12,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse", "-loop", "0", tempURL.path]
        case "extract_mp3":
            args += ["-vn", "-ar", "44100", "-codec:a", "libmp3lame", "-b:a", "192k", "-write_id3v2", "1", "-id3v2_version", "3", tempURL.path]
        default:
            return .failure(ToolError.invalidInput("Formato de vídeo inválido: \(option.id)"))
        }

        let res = ShellRunner.run(executable: ffmpeg, arguments: args, timeout: 1800)
        guard res.status == 0, FileManager.default.fileExists(atPath: tempURL.path) else {
            return .failure(ToolError.commandFailed(res.stderr))
        }
        do {
            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
            return .success(outputURL)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Images

    static func convertImage(inputURLs: [URL], option: ToolOption) -> Result<URL, Error> {
        guard let primary = inputURLs.first?.standardizedFileURL else {
            return .failure(ToolError.emptyInput)
        }
        for url in inputURLs where !FileManager.default.fileExists(atPath: url.path) {
            return .failure(ToolError.inputMissing(url.path))
        }

        let outputURL = option.outputURL(for: primary)
        if inputURLs.count == 1 && primary == outputURL {
            return .failure(ToolError.sameOutputPath)
        }

        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-tmp-\(UUID().uuidString).\(option.outputExtension)")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        if option.id == "pdf" {
            let doc = PDFDocument()
            for (idx, imgURL) in inputURLs.enumerated() {
                guard let nsImg = loadNSImage(at: imgURL), let page = PDFPage(image: nsImg) else {
                    return .failure(ToolError.invalidInput("Não foi possível ler a imagem: \(imgURL.lastPathComponent)"))
                }
                doc.insert(page, at: idx)
            }
            guard doc.write(to: tempURL) else {
                return .failure(ToolError.commandFailed("Falha ao gravar PDF das imagens."))
            }
            do {
                try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                return .success(outputURL)
            } catch {
                return .failure(error)
            }
        }

        // WebP via cwebp / dwebp (or Pillow/ffmpeg fallback)
        let inExt = primary.pathExtension.lowercased()
        if option.id == "webp" || inExt == "webp" {
            if option.id == "webp" {
                guard let cgImg = loadCGImage(at: primary) else {
                    return .failure(ToolError.invalidInput("Não foi possível carregar a imagem: \(primary.lastPathComponent)"))
                }
                let tmpPNG = folder.appendingPathComponent(".sotao57-webp-src-\(UUID().uuidString).png")
                defer { try? FileManager.default.removeItem(at: tmpPNG) }
                guard writePNGTemp(cgImg, to: tmpPNG) else {
                    return .failure(ToolError.commandFailed("Falha ao preparar imagem temporária para WebP."))
                }
                if let cwebp = ShellRunner.findExecutable(["cwebp"]) {
                    let res = ShellRunner.run(executable: cwebp, arguments: ["-quiet", "-q", "88", tmpPNG.path, "-o", tempURL.path], timeout: 120)
                    if res.status == 0, FileManager.default.fileExists(atPath: tempURL.path) {
                        do {
                            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                            return .success(outputURL)
                        } catch {
                            return .failure(error)
                        }
                    }
                    return .failure(ToolError.commandFailed(res.stderr))
                }
                if let pythonBin = ShellRunner.findExecutable(["python3"]) {
                    let pyRes = ShellRunner.run(
                        executable: pythonBin,
                        arguments: ["-c", "import sys; from PIL import Image; Image.open(sys.argv[1]).save(sys.argv[2], 'WEBP', quality=88)", tmpPNG.path, tempURL.path],
                        timeout: 120
                    )
                    if pyRes.status == 0, FileManager.default.fileExists(atPath: tempURL.path) {
                        do {
                            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                            return .success(outputURL)
                        } catch {
                            return .failure(error)
                        }
                    }
                }
                return .failure(ToolError.missingTool("cwebp (webp)", "brew install webp"))
            } else {
                guard let cgImg = loadCGImage(at: primary) else {
                    return .failure(ToolError.invalidInput("Não foi possível decodificar a imagem WebP."))
                }
                return writeCGImage(cgImg, to: tempURL, finalURL: outputURL, targetID: option.id)
            }
        }

        guard let cgImg = loadCGImage(at: primary) else {
            return .failure(ToolError.invalidInput("Não foi possível carregar a imagem: \(primary.lastPathComponent)"))
        }
        return writeCGImage(cgImg, to: tempURL, finalURL: outputURL, targetID: option.id)
    }

    static func loadNSImage(at url: URL) -> NSImage? {
        if let cg = loadCGImage(at: url) {
            return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        }
        return NSImage(contentsOf: url)
    }

    static func loadCGImage(at url: URL) -> CGImage? {
        if let src = CGImageSourceCreateWithURL(url as CFURL, nil),
           let img = CGImageSourceCreateImageAtIndex(src, 0, nil) {
            return img
        }
        if url.pathExtension.lowercased() == "webp" {
            let tmpPNG = FileManager.default.temporaryDirectory.appendingPathComponent("sotao57-\(UUID().uuidString).png")
            defer { try? FileManager.default.removeItem(at: tmpPNG) }
            if let dwebp = ShellRunner.findExecutable(["dwebp"]) {
                let res = ShellRunner.run(executable: dwebp, arguments: ["-quiet", url.path, "-o", tmpPNG.path])
                if res.status == 0,
                   let src = CGImageSourceCreateWithURL(tmpPNG as CFURL, nil),
                   let img = CGImageSourceCreateImageAtIndex(src, 0, nil) {
                    return img
                }
            }
            if let ffmpeg = ShellRunner.findExecutable(["ffmpeg"]) {
                let res = ShellRunner.run(executable: ffmpeg, arguments: ["-y", "-nostdin", "-hide_banner", "-loglevel", "error", "-i", url.path, tmpPNG.path])
                if res.status == 0,
                   let src = CGImageSourceCreateWithURL(tmpPNG as CFURL, nil),
                   let img = CGImageSourceCreateImageAtIndex(src, 0, nil) {
                    return img
                }
            }
        }
        return nil
    }

    private static func writePNGTemp(_ cgImage: CGImage, to url: URL) -> Bool {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            return false
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        return CGImageDestinationFinalize(dest)
    }

    private static func writeCGImage(_ cgImage: CGImage, to tempURL: URL, finalURL: URL, targetID: String) -> Result<URL, Error> {
        let utType: UTType
        switch targetID {
        case "png": utType = .png
        case "jpg": utType = .jpeg
        case "heic": utType = .heic
        case "tiff": utType = .tiff
        default: return .failure(ToolError.invalidInput("Formato de imagem inválido: \(targetID)"))
        }

        guard let dest = CGImageDestinationCreateWithURL(tempURL as CFURL, utType.identifier as CFString, 1, nil) else {
            return .failure(ToolError.commandFailed("Este Mac não suporta gravar o formato \(targetID.uppercased())."))
        }
        let props: [CFString: Any] = (targetID == "jpg" || targetID == "heic")
            ? [kCGImageDestinationLossyCompressionQuality: 0.90]
            : [:]
        CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            return .failure(ToolError.commandFailed("Falha ao finalizar a imagem \(targetID.uppercased())."))
        }
        do {
            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: finalURL)
            return .success(finalURL)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Text & Documents

    static func convertText(inputURL: URL, option: ToolOption) -> Result<URL, Error> {
        let cleanInput = inputURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: cleanInput.path) else {
            return .failure(ToolError.inputMissing(cleanInput.path))
        }
        let inExt = cleanInput.pathExtension.lowercased()
        let outExt = option.outputExtension
        let outputURL = option.outputURL(for: cleanInput)
        if cleanInput == outputURL {
            return .failure(ToolError.sameOutputPath)
        }

        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-tmp-\(UUID().uuidString).\(outExt)")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // 1. From PDF to text / markdown / rtf / html / docx
        if inExt == "pdf" {
            guard let doc = PDFDocument(url: cleanInput) else {
                return .failure(ToolError.invalidInput("Não foi possível abrir o PDF."))
            }
            var extracted = (doc.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if extracted.isEmpty {
                // Scanned PDF: run Apple Vision OCR automatically!
                switch PDFVisionEngine.extractOCRText(inputURL: cleanInput, languages: OCRLanguagePreset.ptEn.codes, progress: nil) {
                case .success(let ocrTxtURL):
                    extracted = (try? String(contentsOf: ocrTxtURL, encoding: .utf8)) ?? ""
                    if outExt == "txt" {
                        try? ShellRunner.replaceAtomically(tempURL: ocrTxtURL, targetURL: outputURL)
                        return .success(outputURL)
                    }
                    try? FileManager.default.removeItem(at: ocrTxtURL)
                case .failure(let err):
                    return .failure(err)
                }
            }
            guard !extracted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .failure(ToolError.invalidInput("O PDF não contém texto reconhecível."))
            }
            if outExt == "txt" || outExt == "md" {
                do {
                    try extracted.write(to: tempURL, atomically: true, encoding: .utf8)
                    try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                    return .success(outputURL)
                } catch {
                    return .failure(error)
                }
            }
            let tmpTxt = folder.appendingPathComponent(".sotao57-pdftxt-\(UUID().uuidString).txt")
            defer { try? FileManager.default.removeItem(at: tmpTxt) }
            do {
                try extracted.write(to: tmpTxt, atomically: true, encoding: .utf8)
            } catch {
                return .failure(error)
            }
            return convertTextViaSystemTools(inputURL: tmpTxt, inExt: "txt", outExt: outExt, tempURL: tempURL, outputURL: outputURL)
        }

        // 2. Target PDF
        if outExt == "pdf" {
            var sourceForOffice = cleanInput
            let intermediateDocx = folder.appendingPathComponent(".sotao57-md-\(UUID().uuidString).docx")
            defer { try? FileManager.default.removeItem(at: intermediateDocx) }

            if inExt == "md" || inExt == "markdown" {
                if let pandoc = ShellRunner.findExecutable(["pandoc"]) {
                    let res = ShellRunner.run(executable: pandoc, arguments: [cleanInput.path, "-o", intermediateDocx.path])
                    if res.status == 0, FileManager.default.fileExists(atPath: intermediateDocx.path) {
                        sourceForOffice = intermediateDocx
                    }
                }
            }

            if let soffice = ShellRunner.findExecutable(["soffice"]) {
                let workOutDir = FileManager.default.temporaryDirectory.appendingPathComponent("sotao57-lo-out-\(UUID().uuidString)")
                let loProfile = FileManager.default.temporaryDirectory.appendingPathComponent("sotao57-lo-prof-\(UUID().uuidString)")
                defer {
                    try? FileManager.default.removeItem(at: workOutDir)
                    try? FileManager.default.removeItem(at: loProfile)
                }
                try? FileManager.default.createDirectory(at: workOutDir, withIntermediateDirectories: true)

                let res = ShellRunner.run(
                    executable: soffice,
                    arguments: [
                        "-env:UserInstallation=file://\(loProfile.path)",
                        "--headless",
                        "--norestore",
                        "--convert-to", "pdf",
                        "--outdir", workOutDir.path,
                        sourceForOffice.path,
                    ],
                    timeout: 180
                )
                let produced = workOutDir.appendingPathComponent(sourceForOffice.deletingPathExtension().lastPathComponent + ".pdf")
                if res.status == 0, FileManager.default.fileExists(atPath: produced.path) {
                    do {
                        try ShellRunner.replaceAtomically(tempURL: produced, targetURL: outputURL)
                        return .success(outputURL)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            // Native macOS PDF rendering fallback for txt/rtf/html
            if ["txt", "rtf", "html", "htm", "md", "markdown"].contains(inExt) {
                return renderDocumentToPDFNatively(inputURL: cleanInput, tempURL: tempURL, outputURL: outputURL)
            }
            return .failure(ToolError.missingTool("LibreOffice (soffice)", "brew install --cask libreoffice"))
        }

        // 3. Markdown or general text formats
        return convertTextViaSystemTools(inputURL: cleanInput, inExt: inExt, outExt: outExt, tempURL: tempURL, outputURL: outputURL)
    }

    private static func convertTextViaSystemTools(
        inputURL: URL,
        inExt: String,
        outExt: String,
        tempURL: URL,
        outputURL: URL
    ) -> Result<URL, Error> {
        let isMarkdownInvolved = (inExt == "md" || inExt == "markdown" || outExt == "md")

        if isMarkdownInvolved {
            if let pandoc = ShellRunner.findExecutable(["pandoc"]) {
                let targetFormat = (outExt == "md") ? "gfm" : outExt
                let args: [String] = (outExt == "html")
                    ? [inputURL.path, "-s", "-o", tempURL.path]
                    : [inputURL.path, "-t", targetFormat, "-o", tempURL.path]
                let res = ShellRunner.run(executable: pandoc, arguments: args, timeout: 120)
                if res.status == 0, FileManager.default.fileExists(atPath: tempURL.path) {
                    do {
                        try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                        return .success(outputURL)
                    } catch {
                        return .failure(error)
                    }
                }
                return .failure(ToolError.commandFailed(res.stderr))
            }
            // Trivial txt <-> md fallback without pandoc
            if (inExt == "md" || inExt == "markdown" || inExt == "txt") && (outExt == "txt" || outExt == "md") {
                do {
                    try FileManager.default.copyItem(at: inputURL, to: tempURL)
                    try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                    return .success(outputURL)
                } catch {
                    return .failure(error)
                }
            }
            return .failure(ToolError.missingTool("pandoc", "brew install pandoc"))
        }

        // Native macOS textutil handles txt, rtf, html, doc, docx, odt
        if let textutil = ShellRunner.findExecutable(["textutil"]) {
            let res = ShellRunner.run(
                executable: textutil,
                arguments: ["-convert", outExt, "-output", tempURL.path, inputURL.path],
                timeout: 120
            )
            if res.status == 0, FileManager.default.fileExists(atPath: tempURL.path) {
                do {
                    try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                    return .success(outputURL)
                } catch {
                    return .failure(error)
                }
            }
        }

        // LibreOffice fallback
        if let soffice = ShellRunner.findExecutable(["soffice"]) {
            let workOutDir = FileManager.default.temporaryDirectory.appendingPathComponent("sotao57-lo-out-\(UUID().uuidString)")
            let loProfile = FileManager.default.temporaryDirectory.appendingPathComponent("sotao57-lo-prof-\(UUID().uuidString)")
            defer {
                try? FileManager.default.removeItem(at: workOutDir)
                try? FileManager.default.removeItem(at: loProfile)
            }
            try? FileManager.default.createDirectory(at: workOutDir, withIntermediateDirectories: true)
            let res = ShellRunner.run(
                executable: soffice,
                arguments: [
                    "-env:UserInstallation=file://\(loProfile.path)",
                    "--headless", "--norestore",
                    "--convert-to", outExt,
                    "--outdir", workOutDir.path,
                    inputURL.path,
                ],
                timeout: 180
            )
            let produced = workOutDir.appendingPathComponent(inputURL.deletingPathExtension().lastPathComponent + ".\(outExt)")
            if res.status == 0, FileManager.default.fileExists(atPath: produced.path) {
                do {
                    try ShellRunner.replaceAtomically(tempURL: produced, targetURL: outputURL)
                    return .success(outputURL)
                } catch {
                    return .failure(error)
                }
            }
            return .failure(ToolError.commandFailed(res.stderr))
        }

        return .failure(ToolError.commandFailed("Não foi possível converter de .\(inExt) para .\(outExt)."))
    }

    private static func renderDocumentToPDFNatively(inputURL: URL, tempURL: URL, outputURL: URL) -> Result<URL, Error> {
        guard let rawText = try? String(contentsOf: inputURL, encoding: .utf8) else {
            return .failure(ToolError.invalidInput("Não foi possível ler o documento como texto UTF-8."))
        }

        var pageBox = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        guard let ctx = CGContext(tempURL as CFURL, mediaBox: &pageBox, nil) else {
            return .failure(ToolError.commandFailed("Não foi possível criar o contexto PDF."))
        }

        let font = NSFont.systemFont(ofSize: 11)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
        let attrStr = NSAttributedString(string: rawText, attributes: attrs)
        let framesetter = CTFramesetterCreateWithAttributedString(attrStr)

        let textRect = CGRect(x: 50, y: 50, width: pageBox.width - 100, height: pageBox.height - 100)
        var currentRange = CFRange(location: 0, length: 0)
        var done = false

        while !done {
            ctx.beginPDFPage(nil)
            let path = CGMutablePath()
            path.addRect(textRect)
            let frame = CTFramesetterCreateFrame(framesetter, currentRange, path, nil)
            CTFrameDraw(frame, ctx)
            let visible = CTFrameGetVisibleStringRange(frame)
            currentRange.location += visible.length
            if currentRange.location >= attrStr.length || visible.length == 0 {
                done = true
            }
            ctx.endPDFPage()
        }
        ctx.closePDF()

        do {
            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
            return .success(outputURL)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Spreadsheets

    static func convertSpreadsheet(inputURL: URL, option: ToolOption) -> Result<URL, Error> {
        let cleanInput = inputURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: cleanInput.path) else {
            return .failure(ToolError.inputMissing(cleanInput.path))
        }
        let inExt = cleanInput.pathExtension.lowercased()
        let outExt = option.outputExtension
        let outputURL = option.outputURL(for: cleanInput)
        if cleanInput == outputURL {
            return .failure(ToolError.sameOutputPath)
        }

        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-tmp-\(UUID().uuidString).\(outExt)")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let pythonSafeInputs = ["csv", "tsv", "json", "xlsx"]
        let pythonSafeOutputs = ["csv", "tsv", "json", "xlsx"]

        if pythonSafeInputs.contains(inExt) && pythonSafeOutputs.contains(outExt),
           let pythonBin = ShellRunner.findPythonWithOpenpyxl() {
            let pyCode = #"""
import csv, json, pathlib, sys
src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2])
in_ext = sys.argv[3].lower()
out_ext = sys.argv[4].lower()

rows = []
if in_ext in ("csv", "tsv"):
    delim = "\t" if in_ext == "tsv" else ","
    raw = src.read_text(encoding="utf-8-sig", errors="replace")
    if in_ext == "csv":
        try:
            dialect = csv.Sniffer().sniff(raw[:4096], delimiters=",;\t|")
            delim = dialect.delimiter
        except Exception:
            delim = ";" if raw.count(";") > raw.count(",") else ","
    reader = csv.reader(raw.splitlines(), delimiter=delim)
    rows = [list(r) for r in reader]
elif in_ext == "json":
    data = json.loads(src.read_text(encoding="utf-8-sig"))
    if isinstance(data, list) and data:
        if all(isinstance(x, dict) for x in data):
            keys = []
            seen = set()
            for x in data:
                for k in x.keys():
                    if k not in seen:
                        seen.add(k)
                        keys.append(str(k))
            rows.append(keys)
            for x in data:
                rows.append(["" if x.get(k) is None else str(x.get(k)) for k in keys])
        elif all(isinstance(x, list) for x in data):
            rows = [[("" if c is None else str(c)) for c in r] for r in data]
        else:
            rows = [["valor"]] + [[str(x)] for x in data]
    elif isinstance(data, dict):
        rows = [["chave", "valor"]] + [[str(k), str(v)] for k, v in data.items()]
elif in_ext == "xlsx":
    import openpyxl
    wb = openpyxl.load_workbook(str(src), data_only=True)
    ws = wb.active
    for row in ws.iter_rows(values_only=True):
        rows.append([("" if c is None else str(c)) for c in row])

if out_ext in ("csv", "tsv"):
    delim = "\t" if out_ext == "tsv" else ","
    with open(dst, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter=delim)
        w.writerows(rows)
elif out_ext == "json":
    if len(rows) >= 2:
        headers = [h if h else f"col_{i+1}" for i, h in enumerate(rows[0])]
        objs = []
        for r in rows[1:]:
            objs.append({headers[i]: (r[i] if i < len(r) else "") for i in range(len(headers))})
        dst.write_text(json.dumps(objs, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    else:
        dst.write_text(json.dumps(rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
elif out_ext == "xlsx":
    import openpyxl
    wb = openpyxl.Workbook()
    ws = wb.active
    for r in rows:
        ws.append(r)
    wb.save(str(dst))
"""#
            let res = ShellRunner.run(
                executable: pythonBin,
                arguments: ["-c", pyCode, cleanInput.path, tempURL.path, inExt, outExt],
                timeout: 120
            )
            if res.status == 0, FileManager.default.fileExists(atPath: tempURL.path) {
                do {
                    try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                    return .success(outputURL)
                } catch {
                    return .failure(error)
                }
            }
            // Fall through to LibreOffice if e.g. openpyxl missing for .xlsx
            if inExt == "json" || outExt == "json" {
                return .failure(ToolError.commandFailed(res.stderr))
            }
        }

        // LibreOffice for .ods, .xls, .pdf or fallback
        guard let soffice = ShellRunner.findExecutable(["soffice"]) else {
            return .failure(ToolError.missingTool("LibreOffice (soffice)", "brew install --cask libreoffice"))
        }

        let workOutDir = FileManager.default.temporaryDirectory.appendingPathComponent("sotao57-lo-out-\(UUID().uuidString)")
        let loProfile = FileManager.default.temporaryDirectory.appendingPathComponent("sotao57-lo-prof-\(UUID().uuidString)")
        defer {
            try? FileManager.default.removeItem(at: workOutDir)
            try? FileManager.default.removeItem(at: loProfile)
        }
        try? FileManager.default.createDirectory(at: workOutDir, withIntermediateDirectories: true)

        let res = ShellRunner.run(
            executable: soffice,
            arguments: [
                "-env:UserInstallation=file://\(loProfile.path)",
                "--headless", "--norestore",
                "--convert-to", outExt,
                "--outdir", workOutDir.path,
                cleanInput.path,
            ],
            timeout: 180
        )
        let produced = workOutDir.appendingPathComponent(cleanInput.deletingPathExtension().lastPathComponent + ".\(outExt)")
        guard res.status == 0, FileManager.default.fileExists(atPath: produced.path) else {
            return .failure(ToolError.commandFailed(res.stderr))
        }
        do {
            try ShellRunner.replaceAtomically(tempURL: produced, targetURL: outputURL)
            return .success(outputURL)
        } catch {
            return .failure(error)
        }
    }
}
