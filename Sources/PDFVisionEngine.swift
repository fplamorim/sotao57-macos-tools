import AppKit
import CoreGraphics
import CoreText
import Foundation
import PDFKit
import Vision

enum PDFVisionEngine {
    // MARK: - Apple Vision OCR

    static func recognizeText(
        in cgImage: CGImage,
        languages: [String]
    ) throws -> [(text: String, boundingBox: CGRect)] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let results = request.results ?? []
        var items: [(text: String, boundingBox: CGRect)] = []
        for obs in results {
            guard let top = obs.topCandidates(1).first else { continue }
            let trimmed = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                items.append((trimmed, obs.boundingBox))
            }
        }
        return items
    }

    private static func renderPageToCGImage(_ page: PDFPage, dpi: CGFloat = 200) -> CGImage? {
        let mediaBox = page.bounds(for: .mediaBox)
        guard mediaBox.width > 0, mediaBox.height > 0 else { return nil }
        let scale = dpi / 72.0
        let width = max(1, Int((mediaBox.width * scale).rounded()))
        let height = max(1, Int((mediaBox.height * scale).rounded()))

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.saveGState()
        ctx.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: ctx)
        ctx.restoreGState()
        return ctx.makeImage()
    }

    private static func drawSearchablePage(
        into pdfContext: CGContext,
        pageRect: CGRect,
        image: CGImage,
        observations: [(text: String, boundingBox: CGRect)]
    ) {
        var box = pageRect
        pdfContext.beginPage(mediaBox: &box)
        pdfContext.draw(image, in: pageRect)

        for item in observations {
            let norm = item.boundingBox
            let rect = CGRect(
                x: norm.origin.x * pageRect.width,
                y: norm.origin.y * pageRect.height,
                width: max(2.0, norm.size.width * pageRect.width),
                height: max(4.0, norm.size.height * pageRect.height)
            )

            let fontSize = max(4.0, rect.height * 0.85)
            let font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
            let attrs: [NSAttributedString.Key: Any] = [
                kCTFontAttributeName as NSAttributedString.Key: font,
            ]
            let attrStr = NSAttributedString(string: item.text, attributes: attrs)
            let line = CTLineCreateWithAttributedString(attrStr)
            let naturalWidth = max(1.0, CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil)))
            let scaleX = rect.width / naturalWidth

            pdfContext.saveGState()
            pdfContext.setTextDrawingMode(.invisible)
            pdfContext.textMatrix = CGAffineTransform(
                a: scaleX, b: 0,
                c: 0, d: 1,
                tx: rect.minX, ty: rect.minY + rect.height * 0.15
            )
            CTLineDraw(line, pdfContext)
            pdfContext.restoreGState()
        }

        pdfContext.endPage()
    }

    // MARK: - 1. OCR on existing PDF -> searchable PDF

    static func ocrPDF(
        inputURL: URL,
        option: ToolOption,
        languages: [String],
        progress: ((String) -> Void)?
    ) -> Result<URL, Error> {
        let cleanInput = inputURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: cleanInput.path) else {
            return .failure(ToolError.inputMissing(cleanInput.path))
        }
        guard let doc = PDFDocument(url: cleanInput) else {
            return .failure(ToolError.invalidInput("Não foi possível abrir o PDF. Se tiver senha, use «Desbloquear PDF» primeiro."))
        }
        if doc.isLocked {
            return .failure(ToolError.invalidInput("Este PDF está protegido por senha. Desbloqueie primeiro em «Desbloquear PDF»."))
        }
        guard doc.pageCount > 0 else {
            return .failure(ToolError.invalidInput("O PDF não possui páginas."))
        }

        let outputURL = option.outputURL(for: cleanInput)
        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-ocr-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var initialRect = doc.page(at: 0)?.bounds(for: .mediaBox) ?? CGRect(x: 0, y: 0, width: 595, height: 842)
        guard let pdfContext = CGContext(tempURL as CFURL, mediaBox: &initialRect, nil) else {
            return .failure(ToolError.commandFailed("Não foi possível iniciar a criação do PDF com OCR."))
        }

        for idx in 0..<doc.pageCount {
            progress?("OCR página \(idx + 1) de \(doc.pageCount)…")
            guard let page = doc.page(at: idx),
                  let cgImg = renderPageToCGImage(page, dpi: 200) else {
                continue
            }
            let pageRect = page.bounds(for: .mediaBox)
            let observations = (try? recognizeText(in: cgImg, languages: languages)) ?? []
            drawSearchablePage(into: pdfContext, pageRect: pageRect, image: cgImg, observations: observations)
        }
        pdfContext.closePDF()

        do {
            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
            return .success(outputURL)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - 2. Images -> searchable PDF with OCR

    static func imagesToOCRPDF(
        inputURLs: [URL],
        option: ToolOption,
        languages: [String],
        progress: ((String) -> Void)?
    ) -> Result<URL, Error> {
        guard let primary = inputURLs.first?.standardizedFileURL else {
            return .failure(ToolError.emptyInput)
        }
        for url in inputURLs where !FileManager.default.fileExists(atPath: url.path) {
            return .failure(ToolError.inputMissing(url.path))
        }

        let outputURL = option.outputURL(for: primary)
        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-imgocr-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var firstRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        if let firstImg = MediaEngines.loadCGImage(at: primary) {
            firstRect = CGRect(x: 0, y: 0, width: CGFloat(firstImg.width), height: CGFloat(firstImg.height))
        }
        guard let pdfContext = CGContext(tempURL as CFURL, mediaBox: &firstRect, nil) else {
            return .failure(ToolError.commandFailed("Não foi possível iniciar a geração do PDF."))
        }

        for (idx, imgURL) in inputURLs.enumerated() {
            progress?("OCR imagem \(idx + 1) de \(inputURLs.count)…")
            guard let cgImg = MediaEngines.loadCGImage(at: imgURL) else {
                pdfContext.closePDF()
                return .failure(ToolError.invalidInput("Não foi possível ler a imagem: \(imgURL.lastPathComponent)"))
            }
            let pageRect = CGRect(x: 0, y: 0, width: CGFloat(cgImg.width), height: CGFloat(cgImg.height))
            let observations = (try? recognizeText(in: cgImg, languages: languages)) ?? []
            drawSearchablePage(into: pdfContext, pageRect: pageRect, image: cgImg, observations: observations)
        }
        pdfContext.closePDF()

        do {
            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
            return .success(outputURL)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - 3. Extract OCR Text -> .txt

    static func extractOCRText(
        inputURL: URL,
        languages: [String],
        progress: ((String) -> Void)?
    ) -> Result<URL, Error> {
        let cleanInput = inputURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: cleanInput.path) else {
            return .failure(ToolError.inputMissing(cleanInput.path))
        }

        let folder = cleanInput.deletingLastPathComponent()
        let stem = cleanInput.deletingPathExtension().lastPathComponent
        let outputURL = folder.appendingPathComponent("\(stem)-ocr.txt").standardizedFileURL
        let tempURL = folder.appendingPathComponent(".sotao57-ocrtxt-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var allPagesText: [String] = []
        if cleanInput.pathExtension.lowercased() == "pdf" {
            guard let doc = PDFDocument(url: cleanInput) else {
                return .failure(ToolError.invalidInput("Não foi possível abrir o PDF."))
            }
            if doc.isLocked {
                return .failure(ToolError.invalidInput("PDF protegido por senha. Desbloqueie primeiro."))
            }
            for idx in 0..<doc.pageCount {
                progress?("Extraindo texto (página \(idx + 1)/\(doc.pageCount))…")
                guard let page = doc.page(at: idx),
                      let cgImg = renderPageToCGImage(page, dpi: 200) else {
                    continue
                }
                let lines = ((try? recognizeText(in: cgImg, languages: languages)) ?? [])
                    .sorted {
                        if abs($0.boundingBox.minY - $1.boundingBox.minY) > 0.015 {
                            return $0.boundingBox.minY > $1.boundingBox.minY
                        }
                        return $0.boundingBox.minX < $1.boundingBox.minX
                    }
                    .map(\.text)
                if !lines.isEmpty {
                    let header = doc.pageCount > 1 ? "=== Página \(idx + 1) ===\n" : ""
                    allPagesText.append(header + lines.joined(separator: "\n"))
                }
            }
        } else {
            guard let cgImg = MediaEngines.loadCGImage(at: cleanInput) else {
                return .failure(ToolError.invalidInput("Não foi possível carregar a imagem."))
            }
            progress?("Executando OCR na imagem…")
            let lines = ((try? recognizeText(in: cgImg, languages: languages)) ?? [])
                .sorted {
                    if abs($0.boundingBox.minY - $1.boundingBox.minY) > 0.015 {
                        return $0.boundingBox.minY > $1.boundingBox.minY
                    }
                    return $0.boundingBox.minX < $1.boundingBox.minX
                }
                .map(\.text)
            if !lines.isEmpty {
                allPagesText.append(lines.joined(separator: "\n"))
            }
        }

        let finalText = allPagesText.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalText.isEmpty else {
            return .failure(ToolError.invalidInput("Nenhum texto foi reconhecido por OCR."))
        }

        do {
            try (finalText + "\n").write(to: tempURL, atomically: true, encoding: .utf8)
            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
            return .success(outputURL)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - 4. Unlock password-protected PDF (with user-supplied password)

    static func unlockPDF(inputURL: URL, option: ToolOption, password: String) -> Result<URL, Error> {
        let cleanInput = inputURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: cleanInput.path) else {
            return .failure(ToolError.inputMissing(cleanInput.path))
        }
        guard let doc = PDFDocument(url: cleanInput) else {
            return .failure(ToolError.invalidInput("Não foi possível abrir o arquivo como PDF."))
        }

        if !doc.isEncrypted && !doc.isLocked {
            return .failure(
                ToolError.unlockFailed(
                    "Este PDF não tem senha/bloqueio de encriptação. Se você não consegue editar o texto porque ele é escaneado (imagem), use a opção «OCR em PDF» acima."
                )
            )
        }

        let trimmedPassword = password
        if trimmedPassword.isEmpty {
            return .failure(ToolError.passwordRequired)
        }

        let outputURL = option.outputURL(for: cleanInput)
        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-unlock-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        if let qpdf = ShellRunner.findExecutable(["qpdf"]) {
            let res = ShellRunner.run(
                executable: qpdf,
                arguments: ["--password=\(trimmedPassword)", "--decrypt", cleanInput.path, tempURL.path],
                timeout: 120
            )
            // qpdf returns 0 on clean success, 3 with non-fatal warnings
            if (res.status == 0 || res.status == 3), FileManager.default.fileExists(atPath: tempURL.path) {
                do {
                    try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
                    return .success(outputURL)
                } catch {
                    return .failure(error)
                }
            }
            if res.stderr.lowercased().contains("invalid password") {
                return .failure(ToolError.unlockFailed("Senha incorreta para desbloquear este PDF."))
            }
        }

        guard doc.unlock(withPassword: trimmedPassword) else {
            return .failure(ToolError.unlockFailed("Senha incorreta ou PDF não pôde ser desbloqueado."))
        }

        // Write unlocked copy without password protection
        guard doc.write(to: tempURL, withOptions: nil),
              let verifyDoc = PDFDocument(url: tempURL),
              !verifyDoc.isLocked else {
            return .failure(ToolError.unlockFailed("Não foi possível gravar a cópia desbloqueada deste PDF."))
        }

        do {
            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
            return .success(outputURL)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - 5. Merge PDFs

    static func mergePDFs(inputURLs: [URL], option: ToolOption) -> Result<URL, Error> {
        let pdfURLs = inputURLs.map(\.standardizedFileURL)
        guard pdfURLs.count >= 2 else {
            return .failure(ToolError.invalidInput("Selecione pelo menos 2 PDFs para juntar."))
        }

        let outputURL = option.outputURL(for: pdfURLs[0])
        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-merge-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let merged = PDFDocument()
        for url in pdfURLs {
            guard FileManager.default.fileExists(atPath: url.path) else {
                return .failure(ToolError.inputMissing(url.path))
            }
            guard let part = PDFDocument(url: url) else {
                return .failure(ToolError.invalidInput("Não foi possível ler o PDF: \(url.lastPathComponent)"))
            }
            if part.isLocked {
                return .failure(ToolError.invalidInput("O PDF '\(url.lastPathComponent)' está protegido por senha."))
            }
            for i in 0..<part.pageCount {
                if let page = part.page(at: i) {
                    merged.insert(page, at: merged.pageCount)
                }
            }
        }

        guard merged.pageCount > 0, merged.write(to: tempURL) else {
            return .failure(ToolError.commandFailed("Falha ao juntar os PDFs."))
        }

        do {
            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
            return .success(outputURL)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - 6. Compress PDF

    static func compressPDF(inputURL: URL, option: ToolOption) -> Result<URL, Error> {
        let cleanInput = inputURL.standardizedFileURL
        guard FileManager.default.fileExists(atPath: cleanInput.path) else {
            return .failure(ToolError.inputMissing(cleanInput.path))
        }
        let outputURL = option.outputURL(for: cleanInput)
        let folder = outputURL.deletingLastPathComponent()
        let tempURL = folder.appendingPathComponent(".sotao57-comp-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        if let gs = ShellRunner.findExecutable(["gs"]) {
            let res = ShellRunner.run(
                executable: gs,
                arguments: [
                    "-sDEVICE=pdfwrite",
                    "-dCompatibilityLevel=1.4",
                    "-dPDFSETTINGS=/ebook",
                    "-dNOPAUSE",
                    "-dQUIET",
                    "-dBATCH",
                    "-sOutputFile=\(tempURL.path)",
                    cleanInput.path,
                ],
                timeout: 180
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

        // Native Quartz JPEG-recompressed PDF fallback
        guard let doc = PDFDocument(url: cleanInput), !doc.isLocked, doc.pageCount > 0 else {
            return .failure(ToolError.invalidInput("Não foi possível abrir o PDF para comprimir."))
        }
        var box = doc.page(at: 0)?.bounds(for: .mediaBox) ?? CGRect(x: 0, y: 0, width: 595, height: 842)
        guard let ctx = CGContext(tempURL as CFURL, mediaBox: &box, nil) else {
            return .failure(ToolError.commandFailed("Falha ao comprimir PDF."))
        }
        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i),
                  let cgImg = renderPageToCGImage(page, dpi: 130) else { continue }
            let rep = NSBitmapImageRep(cgImage: cgImg)
            if let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.65]),
               let provider = CGDataProvider(data: jpegData as CFData),
               let compressedCG = CGImage(jpegDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
                var pBox = page.bounds(for: .mediaBox)
                ctx.beginPage(mediaBox: &pBox)
                ctx.draw(compressedCG, in: pBox)
                ctx.endPage()
            }
        }
        ctx.closePDF()

        do {
            try ShellRunner.replaceAtomically(tempURL: tempURL, targetURL: outputURL)
            return .success(outputURL)
        } catch {
            return .failure(error)
        }
    }
}
