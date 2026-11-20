import Foundation

struct ShellResult {
    let status: Int32
    let stdout: String
    let stderr: String
}

enum ShellRunner {
    private static let searchDirs = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
        "/Applications/LibreOffice.app/Contents/MacOS",
    ]

    static func findExecutable(_ names: [String]) -> String? {
        let envPaths = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
        let dirs = searchDirs + envPaths
        let fm = FileManager.default

        for name in names {
            if name.hasPrefix("/"), fm.isExecutableFile(atPath: name) {
                return name
            }
            for dir in dirs where !dir.isEmpty {
                let candidate = URL(fileURLWithPath: dir).appendingPathComponent(name).path
                if fm.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }
        return nil
    }

    static func findBrew() -> String? {
        findExecutable(["/opt/homebrew/bin/brew", "/usr/local/bin/brew", "brew"])
    }

    static func findPythonWithOpenpyxl() -> String? {
        let candidates = [
            "/Library/Frameworks/Python.framework/Versions/3.14/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.13/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3",
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3",
        ]
        let fm = FileManager.default
        for path in candidates where fm.isExecutableFile(atPath: path) {
            let check = run(
                executable: path,
                arguments: ["-c", "import openpyxl"],
                timeout: 5
            )
            if check.status == 0 {
                return path
            }
        }
        return findExecutable(["python3"])
    }

    static func checkDependencies() -> [DependencyStatus] {
        [
            DependencyStatus(
                id: "vision",
                name: "Apple Vision OCR & PDFKit",
                purpose: L10n.t(
                    "OCR em PDF, Imagem→PDF OCR, Juntar e Imagens nativas",
                    en: "PDF OCR, Image→OCR PDF, PDF Merge & native images",
                    es: "OCR en PDF, Imagen→PDF OCR, Unir PDFs e imágenes nativas"
                ),
                path: "/System/Library/Frameworks/Vision.framework",
                installHint: L10n.t("Nativo do macOS", en: "Built into macOS", es: "Nativo de macOS"),
                isNative: true,
                brewPackage: nil,
                isCask: false,
                defaultSelected: false
            ),
            DependencyStatus(
                id: "textutil",
                name: "macOS textutil / afconvert / sips",
                purpose: L10n.t(
                    "DOCX/RTF/HTML/TXT, AAC/WAV e PNG/JPG/HEIC/TIFF",
                    en: "DOCX/RTF/HTML/TXT, AAC/WAV & PNG/JPG/HEIC/TIFF",
                    es: "DOCX/RTF/HTML/TXT, AAC/WAV y PNG/JPG/HEIC/TIFF"
                ),
                path: findExecutable(["textutil"]),
                installHint: L10n.t("Nativo do macOS", en: "Built into macOS", es: "Nativo de macOS"),
                isNative: true,
                brewPackage: nil,
                isCask: false,
                defaultSelected: false
            ),
            DependencyStatus(
                id: "ffmpeg",
                name: "ffmpeg",
                purpose: L10n.t(
                    "Áudio (.mp3, .opus, .ogg, .flac), Vídeo e extração de áudio Web",
                    en: "Audio (.mp3, .opus, .ogg, .flac), Video & Web audio merge",
                    es: "Audio (.mp3, .opus, .ogg, .flac), Video y descarga Web"
                ),
                path: findExecutable(["ffmpeg"]),
                installHint: "brew install ffmpeg",
                isNative: false,
                brewPackage: "ffmpeg",
                isCask: false,
                defaultSelected: true
            ),
            DependencyStatus(
                id: "yt-dlp",
                name: "yt-dlp",
                purpose: L10n.t(
                    "Download de vídeo e áudio da Web (YouTube, TikTok, LinkedIn, etc.)",
                    en: "Web video & audio downloads (YouTube, TikTok, LinkedIn, etc.)",
                    es: "Descarga de video y audio Web (YouTube, TikTok, LinkedIn, etc.)"
                ),
                path: findExecutable(["yt-dlp"]),
                installHint: "brew install yt-dlp",
                isNative: false,
                brewPackage: "yt-dlp",
                isCask: false,
                defaultSelected: true
            ),
            DependencyStatus(
                id: "pandoc",
                name: "pandoc",
                purpose: L10n.t(
                    "Conversões com Markdown (.md)",
                    en: "Markdown (.md) document conversions",
                    es: "Conversiones con Markdown (.md)"
                ),
                path: findExecutable(["pandoc"]),
                installHint: "brew install pandoc",
                isNative: false,
                brewPackage: "pandoc",
                isCask: false,
                defaultSelected: true
            ),
            DependencyStatus(
                id: "qpdf",
                name: "qpdf",
                purpose: L10n.t(
                    "Desbloqueio vetorial de PDF com senha",
                    en: "Vector-preserving PDF password unlock",
                    es: "Desbloqueo vectorial de PDF con contraseña"
                ),
                path: findExecutable(["qpdf"]),
                installHint: "brew install qpdf",
                isNative: false,
                brewPackage: "qpdf",
                isCask: false,
                defaultSelected: true
            ),
            DependencyStatus(
                id: "gs",
                name: "Ghostscript (gs)",
                purpose: L10n.t(
                    "Compressão avançada de PDFs pesados",
                    en: "Advanced compression for large PDFs",
                    es: "Compresión avanzada de PDFs grandes"
                ),
                path: findExecutable(["gs"]),
                installHint: "brew install ghostscript",
                isNative: false,
                brewPackage: "ghostscript",
                isCask: false,
                defaultSelected: true
            ),
            DependencyStatus(
                id: "cwebp",
                name: "WebP (cwebp / dwebp)",
                purpose: L10n.t(
                    "Conversão de e para imagens .webp",
                    en: "Convert images to and from .webp",
                    es: "Conversión hacia y desde imágenes .webp"
                ),
                path: findExecutable(["cwebp"]),
                installHint: "brew install webp",
                isNative: false,
                brewPackage: "webp",
                isCask: false,
                defaultSelected: true
            ),
            DependencyStatus(
                id: "soffice",
                name: "LibreOffice (soffice)",
                purpose: L10n.t(
                    "Conversão avançada DOCX/ODT/XLSX/ODS → PDF (~350 MB)",
                    en: "Advanced DOCX/ODT/XLSX/ODS → PDF conversion (~350 MB)",
                    es: "Conversión avanzada DOCX/ODT/XLSX/ODS → PDF (~350 MB)"
                ),
                path: findExecutable(["soffice"]),
                installHint: "brew install --cask libreoffice",
                isNative: false,
                brewPackage: "libreoffice",
                isCask: true,
                defaultSelected: false
            ),
        ]
    }

    static func run(
        executable: String,
        arguments: [String],
        extraEnv: [String: String] = [:],
        timeout: TimeInterval = 300
    ) -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        let extraPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PATH"] = env["PATH"].map { "\(extraPath):\($0)" } ?? extraPath
        for (k, v) in extraEnv {
            env[k] = v
        }
        process.environment = env

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = outPipe
        process.standardError = errPipe

        var outData = Data()
        var errData = Data()
        let group = DispatchGroup()

        do {
            try process.run()
        } catch {
            return ShellResult(status: -1, stdout: "", stderr: error.localizedDescription)
        }

        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }

        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }

        let timeoutWork = DispatchWorkItem {
            if process.isRunning {
                process.terminate()
            }
        }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: timeoutWork)

        process.waitUntilExit()
        timeoutWork.cancel()
        group.wait()

        let outText = String(data: outData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errText = String(data: errData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return ShellResult(status: process.terminationStatus, stdout: outText, stderr: errText)
    }

    static func runStreaming(
        executable: String,
        arguments: [String],
        extraEnv: [String: String] = [:],
        timeout: TimeInterval = 900,
        onLine: @escaping (String) -> Void
    ) -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        let extraPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PATH"] = env["PATH"].map { "\(extraPath):\($0)" } ?? extraPath
        for (k, v) in extraEnv {
            env[k] = v
        }
        process.environment = env

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = outPipe
        process.standardError = errPipe

        let pipeQueue = DispatchQueue(label: "com.sotao57.macostools.shellstream")
        var outData = Data()
        var errData = Data()
        var outBuffer = Data()
        var errBuffer = Data()

        func emitLines(from buffer: inout Data) {
            while let idx = buffer.firstIndex(where: { $0 == 0x0A || $0 == 0x0D }) {
                let slice = buffer.subdata(in: 0..<idx)
                buffer.removeSubrange(0...idx)
                if let str = String(data: slice, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !str.isEmpty {
                    onLine(str)
                }
            }
        }

        func flushTrailing(from buffer: inout Data) {
            guard !buffer.isEmpty else { return }
            if let str = String(data: buffer, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !str.isEmpty {
                onLine(str)
            }
            buffer.removeAll()
        }

        outPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            pipeQueue.async {
                outData.append(chunk)
                outBuffer.append(chunk)
                emitLines(from: &outBuffer)
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            pipeQueue.async {
                errData.append(chunk)
                errBuffer.append(chunk)
                emitLines(from: &errBuffer)
            }
        }

        do {
            try process.run()
        } catch {
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            return ShellResult(status: -1, stdout: "", stderr: error.localizedDescription)
        }

        let timeoutWork = DispatchWorkItem {
            if process.isRunning {
                process.terminate()
            }
        }
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: timeoutWork)

        process.waitUntilExit()
        timeoutWork.cancel()

        outPipe.fileHandleForReading.readabilityHandler = nil
        errPipe.fileHandleForReading.readabilityHandler = nil

        var finalOutData = Data()
        var finalErrData = Data()
        pipeQueue.sync {
            let remOut = outPipe.fileHandleForReading.readDataToEndOfFile()
            if !remOut.isEmpty {
                outData.append(remOut)
                outBuffer.append(remOut)
            }
            let remErr = errPipe.fileHandleForReading.readDataToEndOfFile()
            if !remErr.isEmpty {
                errData.append(remErr)
                errBuffer.append(remErr)
            }
            emitLines(from: &outBuffer)
            emitLines(from: &errBuffer)
            flushTrailing(from: &outBuffer)
            flushTrailing(from: &errBuffer)
            finalOutData = outData
            finalErrData = errData
        }

        let outText = String(data: finalOutData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errText = String(data: finalErrData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return ShellResult(status: process.terminationStatus, stdout: outText, stderr: errText)
    }

    static func replaceAtomically(tempURL: URL, targetURL: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: targetURL.path) {
            try fm.removeItem(at: targetURL)
        }
        try fm.moveItem(at: tempURL, to: targetURL)
    }
}
