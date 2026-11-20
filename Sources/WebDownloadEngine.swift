import Foundation

enum WebDownloadEngine {
    static func download(
        urlString: String,
        destinationDir: URL,
        option: ToolOption,
        progress: ((Double?, String) -> Void)?
    ) -> Result<URL, Error> {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = URL(string: trimmed),
              let scheme = parsed.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              let host = parsed.host,
              !host.isEmpty else {
            return .failure(
                ToolError.invalidInput(
                    L10n.t(
                        "Cole um link válido começando com https:// ou http://.",
                        en: "Paste a valid link starting with https:// or http://.",
                        es: "Pega un enlace válido que comience con https:// o http://."
                    )
                )
            )
        }

        guard let ytdlp = ShellRunner.findExecutable(["yt-dlp"]) else {
            return .failure(ToolError.missingTool("yt-dlp", "brew install yt-dlp"))
        }

        let ffmpeg = ShellRunner.findExecutable(["ffmpeg"])
        if (option.id == "audio_mp3" || option.id == "audio_m4a") && ffmpeg == nil {
            return .failure(ToolError.missingTool("ffmpeg", "brew install ffmpeg"))
        }

        let targetDir = destinationDir.standardizedFileURL
        do {
            try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
        } catch {
            return .failure(error)
        }

        let markerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("sotao57-ytdlp-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: markerURL) }

        var args = [
            "--newline",
            "--progress",
            "--no-playlist",
            "--no-part",
            "--windows-filenames",
            "--print-to-file", "after_move:filepath", markerURL.path,
            "-P", targetDir.path,
            "-o", "%(title).80s.%(ext)s",
        ]

        if let ffmpegPath = ffmpeg {
            let binDir = URL(fileURLWithPath: ffmpegPath).deletingLastPathComponent().path
            args += ["--ffmpeg-location", binDir]
        }

        switch option.id {
        case "mp4_best":
            args += [
                "-f", "bv*[ext=mp4]+ba[ext=m4a]/bv*+ba/b[ext=mp4]/b",
                "--merge-output-format", "mp4",
            ]
        case "mp4_1080":
            args += [
                "-f", "bv*[height<=1080][ext=mp4]+ba[ext=m4a]/bv*[height<=1080]+ba/b[height<=1080]/b",
                "--merge-output-format", "mp4",
            ]
        case "mp4_720":
            args += [
                "-f", "bv*[height<=720][ext=mp4]+ba[ext=m4a]/bv*[height<=720]+ba/b[height<=720]/b",
                "--merge-output-format", "mp4",
            ]
        case "audio_mp3":
            args += ["-x", "--audio-format", "mp3", "--audio-quality", "192K"]
        case "audio_m4a":
            args += ["-x", "--audio-format", "m4a", "--audio-quality", "0"]
        default:
            return .failure(ToolError.invalidInput("Formato inválido: \(option.id)"))
        }

        args += ["--", trimmed]

        progress?(
            0.05,
            L10n.t(
                "Conectando e analisando o link…",
                en: "Connecting and analyzing link…",
                es: "Conectando y analizando enlace…"
            )
        )

        let res = ShellRunner.runStreaming(
            executable: ytdlp,
            arguments: args,
            timeout: 1200
        ) { line in
            if let pct = parsePercentage(from: line) {
                let capped = min(max(pct, 0.0), 0.94)
                let percentInt = Int((pct * 100.0).rounded())
                progress?(
                    capped,
                    L10n.t(
                        "Baixando… \(percentInt)%",
                        en: "Downloading… \(percentInt)%",
                        es: "Descargando… \(percentInt)%"
                    )
                )
            } else if line.contains("[Merger]") || line.contains("[ExtractAudio]") || line.contains("[Fixup") {
                progress?(
                    0.96,
                    L10n.t(
                        "Convertendo e finalizando arquivo…",
                        en: "Converting and finalizing file…",
                        es: "Convirtiendo y finalizando archivo…"
                    )
                )
            }
        }

        guard res.status == 0 else {
            let detail = extractErrorLine(stderr: res.stderr, stdout: res.stdout)
            return .failure(ToolError.commandFailed(detail))
        }

        if let content = try? String(contentsOf: markerURL, encoding: .utf8) {
            let paths = content
                .split(whereSeparator: \.isNewline)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if let savedPath = paths.last, FileManager.default.fileExists(atPath: savedPath) {
                return .success(URL(fileURLWithPath: savedPath))
            }
        }

        return .failure(
            ToolError.commandFailed(
                L10n.t(
                    "Download concluído, mas não foi possível localizar o arquivo salvo.",
                    en: "Download finished, but the saved file could not be located.",
                    es: "Descarga finalizada, pero no se pudo encontrar el archivo guardado."
                )
            )
        )
    }

    private static func parsePercentage(from line: String) -> Double? {
        guard line.contains("[download]"), line.contains("%") else { return nil }
        for token in line.split(whereSeparator: { $0 == " " || $0 == "\t" }) {
            let s = String(token)
            if s.hasSuffix("%") {
                let numStr = String(s.dropLast())
                if let val = Double(numStr), val >= 0.0, val <= 100.0 {
                    return val / 100.0
                }
            }
        }
        return nil
    }

    private static func extractErrorLine(stderr: String, stdout: String) -> String {
        let lines = (stderr + "\n" + stdout)
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let errLine = lines.last(where: { $0.hasPrefix("ERROR:") }) {
            return String(errLine.dropFirst("ERROR:".count)).trimmingCharacters(in: .whitespaces)
        }
        return lines.last ?? L10n.t(
            "Falha ao baixar mídia deste link.",
            en: "Failed to download media from this link.",
            es: "Error al descargar multimedia de este enlace."
        )
    }
}
