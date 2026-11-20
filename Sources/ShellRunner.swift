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
                purpose: "OCR em PDF, Imagem→PDF OCR, Juntar e Imagens nativas",
                path: "/System/Library/Frameworks/Vision.framework",
                installHint: "Nativo do macOS"
            ),
            DependencyStatus(
                id: "textutil",
                name: "macOS textutil / afconvert / sips",
                purpose: "DOCX/RTF/HTML/TXT, AAC/WAV e PNG/JPG/HEIC/TIFF",
                path: findExecutable(["textutil"]),
                installHint: "Nativo do macOS"
            ),
            DependencyStatus(
                id: "ffmpeg",
                name: "ffmpeg",
                purpose: "Áudio (.mp3, .opus, .ogg, .flac), Vídeo e WebP",
                path: findExecutable(["ffmpeg"]),
                installHint: "brew install ffmpeg"
            ),
            DependencyStatus(
                id: "soffice",
                name: "LibreOffice (soffice)",
                purpose: "Conversão avançada DOCX/ODT/XLSX/ODS → PDF",
                path: findExecutable(["soffice"]),
                installHint: "brew install --cask libreoffice"
            ),
            DependencyStatus(
                id: "pandoc",
                name: "pandoc",
                purpose: "Conversões com Markdown (.md)",
                path: findExecutable(["pandoc"]),
                installHint: "brew install pandoc"
            ),
            DependencyStatus(
                id: "qpdf",
                name: "qpdf",
                purpose: "Desbloqueio vetorial de PDF com senha",
                path: findExecutable(["qpdf"]),
                installHint: "brew install qpdf"
            ),
            DependencyStatus(
                id: "gs",
                name: "Ghostscript (gs)",
                purpose: "Compressão avançada de PDFs pesados",
                path: findExecutable(["gs"]),
                installHint: "brew install ghostscript"
            ),
        ]
    }

    static func run(
        executable: String,
        arguments: [String],
        timeout: TimeInterval = 300
    ) -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        let extraPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
        env["PATH"] = env["PATH"].map { "\(extraPath):\($0)" } ?? extraPath
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

    static func replaceAtomically(tempURL: URL, targetURL: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: targetURL.path) {
            try fm.removeItem(at: targetURL)
        }
        try fm.moveItem(at: tempURL, to: targetURL)
    }
}
