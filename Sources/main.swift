import AppKit
import Foundation
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .aqua)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .aqua)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        AppViewModel.shared.handleAppLaunched()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ sender: NSApplication, open urls: [URL]) {
        DispatchQueue.main.async {
            AppViewModel.shared.openExternalURLs(urls)
        }
    }
}

struct Sotao57MacOSToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("SOTAO57 macOS Tools", id: "main") {
            RootView()
        }
        .windowResizability(.contentSize)
    }
}

private func jsonEscape(_ text: String) -> String {
    text
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: "\r", with: " ")
}

private func runCLIAndExit(args: [String]) -> Never {
    // --run <category> <option_id> <input_path_or_url(|path2...)> [extra_or_dest_dir]
    let catRaw = args[2].lowercased()
    let optRaw = args[3].lowercased()
    let inputRaw = args[4]
    let extra = args.count > 5 ? args[5] : ""

    guard let category = ToolCategory(rawValue: catRaw) else {
        print("{\"ok\": false, \"error\": \"\(jsonEscape("Invalid category: \(catRaw)"))\"}")
        exit(2)
    }
    guard let option = category.options.first(where: { $0.id == optRaw }) else {
        print("{\"ok\": false, \"error\": \"\(jsonEscape("Invalid option: \(optRaw)"))\"}")
        exit(2)
    }

    let urls: [URL] = (category == .webDownload)
        ? []
        : inputRaw.split(separator: "|").map { URL(fileURLWithPath: String($0)) }

    let ocrLangs = OCRLanguagePreset.allCases
        .first(where: { $0.id == extra || $0.displayName == extra })?
        .codes ?? OCRLanguagePreset.defaultForSystem.codes

    let destDir: URL? = (category == .webDownload && !extra.isEmpty)
        ? URL(fileURLWithPath: extra)
        : nil

    let result = AppViewModel.dispatchConversion(
        category: category,
        option: option,
        inputURLs: urls,
        ocrLanguages: ocrLangs,
        videoQuality: .balanced,
        password: extra,
        webURL: category == .webDownload ? inputRaw : "",
        downloadDirectory: destDir,
        progress: nil,
        fractionProgress: nil
    )

    switch result {
    case .success(let outURL):
        print("{\"ok\": true, \"output\": \"\(jsonEscape(outURL.path))\"}")
        exit(0)
    case .failure(let err):
        print("{\"ok\": false, \"error\": \"\(jsonEscape(err.localizedDescription))\"}")
        exit(1)
    }
}

private func printCheckL10nAndExit() -> Never {
    let lang = L10n.language.rawValue
    let name = jsonEscape(L10n.appName)
    let webTitle = jsonEscape(ToolCategory.webDownload.title)
    let updateLabel = jsonEscape(L10n.t("Atualizações", en: "Updates", es: "Actualizaciones"))
    let downloadBtn = jsonEscape(L10n.t("Baixar", en: "Download", es: "Descargar"))
    print("{\"ok\": true, \"lang\": \"\(lang)\", \"app\": \"\(name)\", \"webTitle\": \"\(webTitle)\", \"updates\": \"\(updateLabel)\", \"downloadBtn\": \"\(downloadBtn)\"}")
    exit(0)
}

private func printCheckDepsAndExit() -> Never {
    let deps = ShellRunner.checkDependencies()
    let hasBrew = ShellRunner.findBrew() != nil
    let items = deps.map { d in
        "{\"id\":\"\(d.id)\",\"installed\":\(d.isInstalled),\"native\":\(d.isNative)}"
    }.joined(separator: ",")
    print("{\"ok\": true, \"hasBrew\": \(hasBrew), \"deps\": [\(items)]}")
    exit(0)
}

private func printCheckUpdateAndExit() -> Never {
    let state = UpdateChecker.checkLatestReleaseSync()
    switch state {
    case .upToDate(let current, let latest, _):
        print("{\"ok\": true, \"status\": \"upToDate\", \"current\": \"\(jsonEscape(current))\", \"latest\": \"\(jsonEscape(latest))\"}")
        exit(0)
    case .updateAvailable(let current, let latest, _, let dmgURL, _):
        let dmg = dmgURL?.absoluteString ?? ""
        print("{\"ok\": true, \"status\": \"updateAvailable\", \"current\": \"\(jsonEscape(current))\", \"latest\": \"\(jsonEscape(latest))\", \"dmg\": \"\(jsonEscape(dmg))\"}")
        exit(0)
    case .failed(let msg):
        print("{\"ok\": false, \"status\": \"failed\", \"error\": \"\(jsonEscape(msg))\"}")
        exit(1)
    default:
        print("{\"ok\": false, \"status\": \"unknown\"}")
        exit(1)
    }
}

let cliArgs = CommandLine.arguments
if cliArgs.count >= 2 && cliArgs[1] == "--check-l10n" {
    printCheckL10nAndExit()
} else if cliArgs.count >= 2 && cliArgs[1] == "--check-deps" {
    printCheckDepsAndExit()
} else if cliArgs.count >= 2 && cliArgs[1] == "--check-update" {
    printCheckUpdateAndExit()
} else if cliArgs.count >= 5 && cliArgs[1] == "--run" {
    runCLIAndExit(args: cliArgs)
} else {
    Sotao57MacOSToolsApp.main()
}
