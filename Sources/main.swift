import AppKit
import Foundation
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
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

struct Sotao57BasicMacToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("SOTAO57 BASIC MAC TOOLS", id: "main") {
            RootView()
        }
        .windowResizability(.contentSize)
    }
}

private func runCLIAndExit(args: [String]) -> Never {
    // --run <category> <option_id> <input_path(|path2...)> [extra_arg]
    let catRaw = args[2].lowercased()
    let optRaw = args[3].lowercased()
    let inputRaw = args[4]
    let extra = args.count > 5 ? args[5] : ""

    guard let category = ToolCategory(rawValue: catRaw) else {
        print("{\"ok\": false, \"error\": \"Categoria inválida: \(catRaw)\"}")
        exit(2)
    }
    guard let option = category.options.first(where: { $0.id == optRaw }) else {
        print("{\"ok\": false, \"error\": \"Opção inválida: \(optRaw)\"}")
        exit(2)
    }

    let urls = inputRaw.split(separator: "|").map { URL(fileURLWithPath: String($0)) }
    let ocrLangs = OCRLanguagePreset.allCases.first(where: { $0.rawValue == extra })?.codes ?? OCRLanguagePreset.ptEn.codes

    let result = AppViewModel.dispatchConversion(
        category: category,
        option: option,
        inputURLs: urls,
        ocrLanguages: ocrLangs,
        videoQuality: .balanced,
        password: extra,
        progress: nil
    )

    switch result {
    case .success(let outURL):
        let escaped = outURL.path.replacingOccurrences(of: "\"", with: "\\\"")
        print("{\"ok\": true, \"output\": \"\(escaped)\"}")
        exit(0)
    case .failure(let err):
        let escaped = err.localizedDescription
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        print("{\"ok\": false, \"error\": \"\(escaped)\"}")
        exit(1)
    }
}

let cliArgs = CommandLine.arguments
if cliArgs.count >= 5, cliArgs[1] == "--run" {
    runCLIAndExit(args: cliArgs)
} else {
    Sotao57BasicMacToolsApp.main()
}
