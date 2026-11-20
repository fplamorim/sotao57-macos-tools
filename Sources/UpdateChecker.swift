import Foundation

enum UpdateCheckState: Equatable {
    case idle
    case checking
    case upToDate(current: String, latest: String, releaseURL: URL)
    case updateAvailable(current: String, latest: String, notes: String, dmgURL: URL?, releaseURL: URL)
    case failed(String)
}

private struct GitHubReleasePayload: Decodable {
    struct Asset: Decodable {
        let name: String
        let browser_download_url: String
    }

    let tag_name: String
    let html_url: String
    let body: String?
    let assets: [Asset]?
}

enum UpdateChecker {
    static let latestAPIURL = URL(string: "https://api.github.com/repos/fplamorim/sotao57-macos-tools/releases/latest")!

    static func normalizedVersion(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") {
            return String(trimmed.dropFirst())
        }
        return trimmed
    }

    static func isRemoteNewer(remote: String, current: String) -> Bool {
        let rParts = parseComponents(normalizedVersion(remote))
        let cParts = parseComponents(normalizedVersion(current))
        let maxCount = max(rParts.count, cParts.count)
        for i in 0..<maxCount {
            let rv = i < rParts.count ? rParts[i] : 0
            let cv = i < cParts.count ? cParts[i] : 0
            if rv != cv {
                return rv > cv
            }
        }
        return false
    }

    private static func parseComponents(_ version: String) -> [Int] {
        let core = version.split(separator: "-").first.map(String.init) ?? version
        return core.split(separator: ".").map { Int($0) ?? 0 }
    }

    /// Invoked strictly when the user clicks the Check Updates button (never automatically).
    static func checkLatestRelease(completion: @escaping (UpdateCheckState) -> Void) {
        let currentVer = L10n.appVersion

        var request = URLRequest(url: latestAPIURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("SOTAO57-macOS-Tools/\(currentVer)", forHTTPHeaderField: "User-Agent")

        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failed(error.localizedDescription))
                return
            }

            if let http = response as? HTTPURLResponse, http.statusCode == 404 {
                completion(.upToDate(current: currentVer, latest: currentVer, releaseURL: L10n.releasesURL))
                return
            }

            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                completion(
                    .failed(
                        L10n.t(
                            "GitHub retornou código HTTP \(http.statusCode).",
                            en: "GitHub returned HTTP \(http.statusCode).",
                            es: "GitHub devolvió el código HTTP \(http.statusCode)."
                        )
                    )
                )
                return
            }

            guard let data else {
                completion(
                    .failed(
                        L10n.t(
                            "Resposta vazia do GitHub.",
                            en: "Empty response from GitHub.",
                            es: "Respuesta vacía de GitHub."
                        )
                    )
                )
                return
            }

            do {
                let decoded = try JSONDecoder().decode(GitHubReleasePayload.self, from: data)
                let latestVer = normalizedVersion(decoded.tag_name)
                let releaseURL = URL(string: decoded.html_url) ?? L10n.releasesURL
                let dmgURL = decoded.assets?
                    .first(where: { $0.name.lowercased().hasSuffix(".dmg") })
                    .flatMap { URL(string: $0.browser_download_url) }

                if isRemoteNewer(remote: latestVer, current: currentVer) {
                    let notes = (decoded.body ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    completion(
                        .updateAvailable(
                            current: currentVer,
                            latest: latestVer,
                            notes: notes,
                            dmgURL: dmgURL,
                            releaseURL: releaseURL
                        )
                    )
                } else {
                    completion(.upToDate(current: currentVer, latest: latestVer, releaseURL: releaseURL))
                }
            } catch {
                completion(.failed(error.localizedDescription))
            }
        }.resume()
    }

    static func checkLatestReleaseSync() -> UpdateCheckState {
        let sem = DispatchSemaphore(value: 0)
        var captured: UpdateCheckState = .failed("Timeout")
        checkLatestRelease { state in
            captured = state
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 20)
        return captured
    }
}
