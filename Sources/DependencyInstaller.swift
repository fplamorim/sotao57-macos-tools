import Foundation

enum DependencyInstaller {
    static var defaultBrewPrefix: String {
        #if arch(arm64)
        return "/opt/homebrew"
        #else
        return "/usr/local"
        #endif
    }

    static func requestAdminAuthorization(prepareBrewPrefix: Bool) -> Result<String?, Error> {
        let user = NSUserName()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        guard !user.isEmpty, user.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return .failure(
                ToolError.invalidInput(
                    L10n.t(
                        "Nome de usuário inválido para preparação do Homebrew.",
                        en: "Invalid username for Homebrew setup.",
                        es: "Nombre de usuario no válido para configurar Homebrew."
                    )
                )
            )
        }

        let prefix = defaultBrewPrefix
        let shellCmd: String
        if prepareBrewPrefix {
            if prefix == "/opt/homebrew" {
                shellCmd = "/bin/mkdir -p '\(prefix)/Homebrew' '\(prefix)/bin' '\(prefix)/etc' '\(prefix)/Caskroom' '\(prefix)/Cellar' '\(prefix)/var/homebrew' && /usr/sbin/chown -R '\(user):admin' '\(prefix)'"
            } else {
                shellCmd = "/bin/mkdir -p '\(prefix)/Homebrew' '\(prefix)/bin' '\(prefix)/etc' '\(prefix)/Caskroom' '\(prefix)/Cellar' '\(prefix)/var/homebrew' && /usr/sbin/chown -R '\(user):admin' '\(prefix)/Homebrew' '\(prefix)/bin' '\(prefix)/etc' '\(prefix)/Caskroom' '\(prefix)/Cellar' '\(prefix)/var/homebrew'"
            }
        } else {
            shellCmd = "/usr/bin/true"
        }

        let prompt = L10n.t(
            "SOTAO57 macOS Tools precisa de autorização para preparar e instalar as dependências selecionadas.",
            en: "SOTAO57 macOS Tools needs authorization to prepare and install the selected dependencies.",
            es: "SOTAO57 macOS Tools necesita autorización para preparar e instalar las dependencias seleccionadas."
        )

        let escapedCmd = escapeAppleScript(shellCmd)
        let escapedPrompt = escapeAppleScript(prompt)
        let script = "do shell script \"\(escapedCmd)\" with administrator privileges with prompt \"\(escapedPrompt)\""

        let res = ShellRunner.run(
            executable: "/usr/bin/osascript",
            arguments: ["-e", script],
            timeout: 180
        )

        if res.status == 0 {
            return .success(prepareBrewPrefix ? prefix : nil)
        }

        let errLower = res.stderr.lowercased()
        if errLower.contains("user canceled") || errLower.contains("-128") || errLower.contains("cancel") {
            return .failure(
                ToolError.invalidInput(
                    L10n.t(
                        "Autorização cancelada pelo utilizador.",
                        en: "Authorization canceled by user.",
                        es: "Autorización cancelada por el usuario."
                    )
                )
            )
        }

        return .failure(
            ToolError.commandFailed(
                res.stderr.isEmpty
                    ? L10n.t("Não foi possível obter autorização do macOS.", en: "Could not obtain macOS authorization.", es: "No se pudo obtener autorización de macOS.")
                    : res.stderr
            )
        )
    }

    static func bootstrapHomebrew(prefix: String, onLog: @escaping (String) -> Void) -> Result<String, Error> {
        let brewPath = "\(prefix)/bin/brew"
        if FileManager.default.isExecutableFile(atPath: brewPath) {
            return .success(brewPath)
        }

        onLog(
            L10n.t(
                "Baixando gerenciador Homebrew para \(prefix)…",
                en: "Downloading Homebrew package manager into \(prefix)…",
                es: "Descargando gestor Homebrew en \(prefix)…"
            )
        )

        let cmd = "/usr/bin/curl -fsSL https://github.com/Homebrew/brew/tarball/master | /usr/bin/tar xz --strip-components 1 -C '\(prefix)/Homebrew' && /bin/ln -sf '../Homebrew/bin/brew' '\(brewPath)'"
        let res = ShellRunner.runStreaming(
            executable: "/bin/sh",
            arguments: ["-c", cmd],
            extraEnv: ["NONINTERACTIVE": "1"],
            timeout: 600,
            onLine: onLog
        )

        guard res.status == 0, FileManager.default.isExecutableFile(atPath: brewPath) else {
            return .failure(
                ToolError.commandFailed(
                    res.stderr.isEmpty
                        ? L10n.t("Falha ao instalar o Homebrew.", en: "Failed to install Homebrew.", es: "Error al instalar Homebrew.")
                        : res.stderr
                )
            )
        }

        _ = ShellRunner.runStreaming(
            executable: brewPath,
            arguments: ["update", "--force", "--quiet"],
            extraEnv: ["NONINTERACTIVE": "1", "HOMEBREW_NO_ANALYTICS": "1"],
            timeout: 300,
            onLine: onLog
        )

        return .success(brewPath)
    }

    static func installPackage(
        brewPath: String,
        dep: DependencyStatus,
        onLog: @escaping (String) -> Void
    ) -> Result<Void, Error> {
        guard let pkg = dep.brewPackage else {
            return .success(())
        }

        let args = dep.isCask ? ["install", "--cask", pkg] : ["install", pkg]
        let env = [
            "NONINTERACTIVE": "1",
            "HOMEBREW_NO_AUTO_UPDATE": "1",
            "HOMEBREW_NO_ANALYTICS": "1",
            "HOMEBREW_NO_ENV_HINTS": "1",
        ]

        let res = ShellRunner.runStreaming(
            executable: brewPath,
            arguments: args,
            extraEnv: env,
            timeout: 1200,
            onLine: onLog
        )

        // Confirm whether the target executable became available even if a secondary upgrade had a link warning
        if res.status == 0 || ShellRunner.findExecutable([dep.id]) != nil {
            return .success(())
        }

        let errLines = (res.stderr + "\n" + res.stdout)
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .suffix(3)
            .joined(separator: " ")

        return .failure(
            ToolError.commandFailed(
                errLines.isEmpty
                    ? L10n.t("Falha ao instalar \(dep.name).", en: "Failed to install \(dep.name).", es: "Error al instalar \(dep.name).")
                    : errLines
            )
        )
    }

    private static func escapeAppleScript(_ str: String) -> String {
        str
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
