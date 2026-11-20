import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum OperationState: Equatable {
    case idle
    case running(String)
    case success(URL, String)
    case error(String)
}

final class AppViewModel: ObservableObject {
    static let shared = AppViewModel()
    static let setupCompletedKey = "sotao57.setupCompleted.v1_1"

    // Main navigation & workspace
    @Published var activeCategory: ToolCategory? = nil
    @Published var inputURLs: [URL] = []
    @Published var selectedOption: ToolOption = ToolCategory.audio.options[0]
    @Published var ocrLanguage: OCRLanguagePreset = OCRLanguagePreset.defaultForSystem
    @Published var videoQuality: VideoQuality = .balanced
    @Published var pdfPassword: String = ""
    @Published var operationState: OperationState = .idle
    @Published var operationProgress: Double? = nil
    @Published var isDropTargeted: Bool = false
    @Published var copiedHint: Bool = false

    // Web Downloader
    @Published var webURL: String = ""
    @Published var downloadDirectory: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSHomeDirectory())

    // Setup Wizard & Dependencies
    @Published var showingSetupWizard: Bool = false
    @Published var wizardStep: SetupWizardStep = .check
    @Published var dependencies: [DependencyStatus] = []
    @Published var hasBrew: Bool = false
    @Published var selectedBrewPackages: Set<String> = []
    @Published var packageStates: [String: PackageInstallState] = [:]
    @Published var wizardProgress: Double = 0.0
    @Published var wizardCurrentPackage: String = ""
    @Published var wizardLogLines: [String] = []
    @Published var wizardAuthError: String? = nil
    @Published var wizardInstalledCount: Int = 0
    @Published var wizardFailedCount: Int = 0
    @Published var wizardIsWorking: Bool = false

    // Manual-only GitHub Update Checker & About
    @Published var showingUpdateSheet: Bool = false
    @Published var updateState: UpdateCheckState = .idle
    @Published var showingAbout: Bool = false

    var primaryInputURL: URL? { inputURLs.first }

    var isRunning: Bool {
        if case .running = operationState { return true }
        return false
    }

    var canExecute: Bool {
        guard !isRunning else { return false }
        if activeCategory == .webDownload {
            return !webURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !inputURLs.isEmpty else { return false }
        if selectedOption.id == "merge" && inputURLs.count < 2 {
            return false
        }
        return true
    }

    var missingCoreDependenciesCount: Int {
        dependencies.filter { !$0.isNative && $0.defaultSelected && !$0.isInstalled }.count
    }

    var missingOptionalDependencies: [DependencyStatus] {
        dependencies.filter { !$0.isNative && !$0.isInstalled }
    }

    // MARK: - App Lifecycle (First-launch Setup Wizard, NEVER auto-checks updates)

    func handleAppLaunched() {
        DispatchQueue.global(qos: .userInitiated).async {
            let deps = ShellRunner.checkDependencies()
            let brewFound = ShellRunner.findBrew() != nil
            DispatchQueue.main.async {
                self.dependencies = deps
                self.hasBrew = brewFound
                let completed = UserDefaults.standard.bool(forKey: Self.setupCompletedKey)
                if !completed && !self.showingSetupWizard {
                    self.openSetupWizard(usingExistingCheck: true)
                }
            }
        }
    }

    // MARK: - Navigation & Workspace

    func openCategory(_ category: ToolCategory) {
        activeCategory = category
        inputURLs = []
        selectedOption = category.options[0]
        pdfPassword = ""
        operationState = .idle
        operationProgress = nil
        copiedHint = false
    }

    func goHome() {
        guard !isRunning else { return }
        activeCategory = nil
        inputURLs = []
        pdfPassword = ""
        operationState = .idle
        operationProgress = nil
        copiedHint = false
    }

    func selectOption(_ option: ToolOption) {
        selectedOption = option
        if !option.supportsMultipleInputs && inputURLs.count > 1, let first = inputURLs.first {
            inputURLs = [first]
        }
        if case .error = operationState {
            operationState = .idle
        }
    }

    func clearFiles() {
        inputURLs = []
        pdfPassword = ""
        operationState = .idle
        operationProgress = nil
        copiedHint = false
    }

    func setFiles(_ urls: [URL], append: Bool = false) {
        let valid = urls.map(\.standardizedFileURL).filter { !$0.hasDirectoryPath }
        guard !valid.isEmpty else { return }

        if append && selectedOption.supportsMultipleInputs {
            var existing = Set(inputURLs)
            for u in valid where !existing.contains(u) {
                inputURLs.append(u)
                existing.insert(u)
            }
        } else if selectedOption.supportsMultipleInputs {
            inputURLs = valid
        } else {
            inputURLs = [valid[0]]
        }

        operationState = .idle
        operationProgress = nil
        copiedHint = false

        if let first = inputURLs.first,
           let cat = activeCategory,
           selectedOption.fileSuffix.isEmpty,
           first.pathExtension.lowercased() == selectedOption.outputExtension {
            if let alt = cat.options.first(where: { $0.outputExtension != selectedOption.outputExtension || !$0.fileSuffix.isEmpty }) {
                selectedOption = alt
            }
        }
    }

    func openExternalURLs(_ urls: [URL]) {
        guard let first = urls.first else { return }
        let ext = first.pathExtension.lowercased()
        let matched = ToolCategory.allCases.first { $0.acceptedExtensions.contains(ext) } ?? .pdf
        openCategory(matched)
        if ext == "pdf" && matched == .pdf {
            selectedOption = matched.options[0]
        } else if matched == .pdf && ["png", "jpg", "jpeg", "heic", "tiff", "webp"].contains(ext) {
            if let imgOcr = matched.options.first(where: { $0.id == "img_ocr_pdf" }) {
                selectedOption = imgOcr
            }
        }
        setFiles(urls)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openFilePicker(append: Bool = false) {
        guard let cat = activeCategory, cat != .webDownload else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = selectedOption.supportsMultipleInputs
        panel.message = selectedOption.supportsMultipleInputs
            ? L10n.t("Selecione um ou mais arquivos", en: "Select one or more files", es: "Selecciona uno o más archivos")
            : L10n.t("Escolha o arquivo para processar", en: "Choose a file to process", es: "Elige el archivo a procesar")

        let allowed = cat.acceptedExtensions.compactMap { UTType(filenameExtension: $0) }
        if !allowed.isEmpty {
            panel.allowedContentTypes = allowed
        }

        if panel.runModal() == .OK {
            setFiles(panel.urls, append: append)
        }
    }

    func pasteWebURL() {
        if let str = NSPasteboard.general.string(forType: .string) {
            webURL = str.trimmingCharacters(in: .whitespacesAndNewlines)
            if case .error = operationState {
                operationState = .idle
            }
        }
    }

    func clearWebURL() {
        webURL = ""
        operationState = .idle
        operationProgress = nil
        copiedHint = false
    }

    func pickDownloadDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = downloadDirectory
        panel.message = L10n.t(
            "Escolha a pasta onde os downloads serão salvos",
            en: "Choose the folder where downloads will be saved",
            es: "Elige la carpeta donde se guardarán las descargas"
        )
        if panel.runModal() == .OK, let url = panel.url {
            downloadDirectory = url.standardizedFileURL
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard activeCategory != .webDownload else { return false }
        let matching = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !matching.isEmpty else { return false }

        let group = DispatchGroup()
        let lock = NSLock()
        var collected: [URL] = []

        for provider in matching {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                var resolved: URL?
                if let url = item as? URL {
                    resolved = url
                } else if let nsurl = item as? NSURL {
                    resolved = nsurl as URL
                } else if let data = item as? Data {
                    resolved = URL(dataRepresentation: data, relativeTo: nil)
                }
                if let finalURL = resolved, !finalURL.hasDirectoryPath {
                    lock.lock()
                    collected.append(finalURL)
                    lock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if !collected.isEmpty {
                let shouldAppend = self.selectedOption.supportsMultipleInputs && !self.inputURLs.isEmpty
                self.setFiles(collected, append: shouldAppend)
            }
        }
        return true
    }

    // MARK: - Setup Wizard

    func refreshDependencies() {
        dependencies = ShellRunner.checkDependencies()
        hasBrew = ShellRunner.findBrew() != nil
    }

    func openSetupWizard(usingExistingCheck: Bool = false) {
        if !usingExistingCheck {
            refreshDependencies()
        }
        let defaults = dependencies
            .filter { !$0.isNative && !$0.isInstalled && $0.defaultSelected }
            .map(\.id)
        selectedBrewPackages = Set(defaults)
        wizardStep = .check
        wizardProgress = 0.0
        wizardCurrentPackage = ""
        wizardLogLines = []
        wizardAuthError = nil
        packageStates = [:]
        wizardInstalledCount = 0
        wizardFailedCount = 0
        wizardIsWorking = false
        showingSetupWizard = true
    }

    func recheckDependenciesInWizard() {
        refreshDependencies()
        let missingIDs = Set(missingOptionalDependencies.map(\.id))
        selectedBrewPackages = selectedBrewPackages.intersection(missingIDs)
        if selectedBrewPackages.isEmpty {
            let defaults = dependencies
                .filter { !$0.isNative && !$0.isInstalled && $0.defaultSelected }
                .map(\.id)
            selectedBrewPackages = Set(defaults)
        }
    }

    func toggleBrewPackage(_ id: String) {
        if selectedBrewPackages.contains(id) {
            selectedBrewPackages.remove(id)
        } else {
            selectedBrewPackages.insert(id)
        }
    }

    func startWizardInstall() {
        guard !wizardIsWorking else { return }
        let selectedDeps = dependencies.filter { selectedBrewPackages.contains($0.id) && !$0.isNative }
        let needBrewInstall = !hasBrew
        guard needBrewInstall || !selectedDeps.isEmpty else {
            wizardStep = .done
            return
        }

        wizardAuthError = nil
        wizardIsWorking = true

        let needsAdminPrompt = needBrewInstall || selectedDeps.contains(where: { $0.isCask })

        DispatchQueue.global(qos: .userInitiated).async {
            var customBrewPrefix: String? = nil
            if needsAdminPrompt {
                switch DependencyInstaller.requestAdminAuthorization(prepareBrewPrefix: needBrewInstall) {
                case .success(let prefix):
                    customBrewPrefix = prefix
                case .failure(let err):
                    DispatchQueue.main.async {
                        self.wizardAuthError = err.localizedDescription
                        self.wizardIsWorking = false
                    }
                    return
                }
            }

            DispatchQueue.main.async {
                self.wizardStep = .installing
                self.wizardLogLines = []
                self.packageStates = Dictionary(uniqueKeysWithValues: selectedDeps.map { ($0.id, .pending) })
                self.wizardInstalledCount = 0
                self.wizardFailedCount = 0
                self.wizardProgress = 0.04
            }

            let totalSteps = Double((needBrewInstall ? 1 : 0) + max(selectedDeps.count, 0))
            var completedSteps = 0.0
            var brewExecutable = ShellRunner.findBrew()

            func appendLog(_ line: String) {
                let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !clean.isEmpty else { return }
                DispatchQueue.main.async {
                    self.wizardLogLines.append(clean)
                    if self.wizardLogLines.count > 120 {
                        self.wizardLogLines.removeFirst(self.wizardLogLines.count - 120)
                    }
                }
            }

            if needBrewInstall {
                let prefix = customBrewPrefix ?? DependencyInstaller.defaultBrewPrefix
                DispatchQueue.main.async {
                    self.wizardCurrentPackage = L10n.t(
                        "Preparando Homebrew (\(prefix))…",
                        en: "Setting up Homebrew (\(prefix))…",
                        es: "Configurando Homebrew (\(prefix))…"
                    )
                }
                switch DependencyInstaller.bootstrapHomebrew(prefix: prefix, onLog: appendLog) {
                case .success(let path):
                    brewExecutable = path
                    completedSteps += 1.0
                    DispatchQueue.main.async {
                        self.hasBrew = true
                        self.wizardProgress = min(0.98, completedSteps / max(1.0, totalSteps))
                    }
                case .failure(let err):
                    appendLog(err.localizedDescription)
                    DispatchQueue.main.async {
                        self.wizardFailedCount = max(1, selectedDeps.count)
                        for dep in selectedDeps {
                            self.packageStates[dep.id] = .failed(err.localizedDescription)
                        }
                        self.wizardProgress = 1.0
                        self.wizardIsWorking = false
                        self.wizardStep = .done
                    }
                    return
                }
            }

            guard let brewPath = brewExecutable else {
                DispatchQueue.main.async {
                    self.wizardFailedCount = max(1, selectedDeps.count)
                    self.wizardProgress = 1.0
                    self.wizardIsWorking = false
                    self.wizardStep = .done
                }
                return
            }

            var okCount = 0
            var failCount = 0

            for (idx, dep) in selectedDeps.enumerated() {
                DispatchQueue.main.async {
                    self.packageStates[dep.id] = .installing
                    self.wizardCurrentPackage = L10n.t(
                        "Instalando \(idx + 1)/\(selectedDeps.count): \(dep.name)…",
                        en: "Installing \(idx + 1)/\(selectedDeps.count): \(dep.name)…",
                        es: "Instalando \(idx + 1)/\(selectedDeps.count): \(dep.name)…"
                    )
                }
                appendLog("==> brew install \(dep.isCask ? "--cask " : "")\(dep.brewPackage ?? dep.id)")

                switch DependencyInstaller.installPackage(brewPath: brewPath, dep: dep, onLog: appendLog) {
                case .success:
                    okCount += 1
                    completedSteps += 1.0
                    DispatchQueue.main.async {
                        self.packageStates[dep.id] = .installed
                        self.wizardInstalledCount = okCount
                        self.wizardProgress = min(0.99, completedSteps / max(1.0, totalSteps))
                    }
                case .failure(let err):
                    failCount += 1
                    completedSteps += 1.0
                    appendLog("ERROR [\(dep.name)]: \(err.localizedDescription)")
                    DispatchQueue.main.async {
                        self.packageStates[dep.id] = .failed(err.localizedDescription)
                        self.wizardFailedCount = failCount
                        self.wizardProgress = min(0.99, completedSteps / max(1.0, totalSteps))
                    }
                }
            }

            let updatedDeps = ShellRunner.checkDependencies()
            let brewNow = ShellRunner.findBrew() != nil
            DispatchQueue.main.async {
                self.dependencies = updatedDeps
                self.hasBrew = brewNow
                self.wizardProgress = 1.0
                self.wizardCurrentPackage = ""
                self.wizardIsWorking = false
                self.wizardStep = .done
            }
        }
    }

    func finishWizardWithoutRestart() {
        UserDefaults.standard.set(true, forKey: Self.setupCompletedKey)
        showingSetupWizard = false
    }

    func finishWizardAndRestart() {
        UserDefaults.standard.set(true, forKey: Self.setupCompletedKey)
        let bundlePath = Bundle.main.bundlePath
        if bundlePath.hasSuffix(".app") {
            let escaped = bundlePath.replacingOccurrences(of: "'", with: "'\\''")
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/sh")
            proc.arguments = ["-c", "sleep 0.6 && /usr/bin/open -n '\(escaped)'"]
            proc.standardInput = FileHandle.nullDevice
            proc.standardOutput = FileHandle.nullDevice
            proc.standardError = FileHandle.nullDevice
            try? proc.run()
        }
        showingSetupWizard = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NSApp.terminate(nil)
        }
    }

    // MARK: - Manual GitHub Update Checker

    func openUpdateCheckerAndRun() {
        showingUpdateSheet = true
        runManualUpdateCheck()
    }

    func runManualUpdateCheck() {
        updateState = .checking
        UpdateChecker.checkLatestRelease { newState in
            DispatchQueue.main.async {
                self.updateState = newState
            }
        }
    }

    // MARK: - Execution

    func executeActiveTool() {
        guard let cat = activeCategory else { return }
        if cat != .webDownload && inputURLs.isEmpty { return }
        if cat == .webDownload && webURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return }

        let option = selectedOption
        let files = inputURLs
        let langCodes = ocrLanguage.codes
        let vidQuality = videoQuality
        let pwd = pdfPassword
        let linkURL = webURL
        let destDir = downloadDirectory

        copiedHint = false
        operationProgress = (cat == .webDownload) ? 0.02 : nil
        operationState = .running(
            cat == .webDownload
                ? L10n.t("Preparando download…", en: "Preparing download…", es: "Preparando descarga…")
                : L10n.t("Processando \(option.title)…", en: "Processing \(option.title)…", es: "Procesando \(option.title)…")
        )

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Self.dispatchConversion(
                category: cat,
                option: option,
                inputURLs: files,
                ocrLanguages: langCodes,
                videoQuality: vidQuality,
                password: pwd,
                webURL: linkURL,
                downloadDirectory: destDir,
                progress: { msg in
                    DispatchQueue.main.async {
                        self.operationState = .running(msg)
                    }
                },
                fractionProgress: { pct, msg in
                    DispatchQueue.main.async {
                        self.operationProgress = pct
                        self.operationState = .running(msg)
                    }
                }
            )

            DispatchQueue.main.async {
                self.operationProgress = nil
                switch result {
                case .success(let outURL):
                    let sizeText = self.formattedFileSize(outURL)
                    self.operationState = .success(outURL, sizeText.isEmpty ? "OK" : sizeText)
                case .failure(let err):
                    self.operationState = .error(err.localizedDescription)
                }
            }
        }
    }

    static func dispatchConversion(
        category: ToolCategory,
        option: ToolOption,
        inputURLs: [URL],
        ocrLanguages: [String],
        videoQuality: VideoQuality,
        password: String,
        webURL: String = "",
        downloadDirectory: URL? = nil,
        progress: ((String) -> Void)?,
        fractionProgress: ((Double?, String) -> Void)? = nil
    ) -> Result<URL, Error> {
        if category == .webDownload {
            let dir = downloadDirectory
                ?? FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory())
            return WebDownloadEngine.download(
                urlString: webURL,
                destinationDir: dir,
                option: option,
                progress: { pct, msg in
                    if let fractionProgress {
                        fractionProgress(pct, msg)
                    } else {
                        progress?(msg)
                    }
                }
            )
        }

        guard let first = inputURLs.first else {
            return .failure(ToolError.emptyInput)
        }
        switch category {
        case .audio:
            return MediaEngines.convertAudio(inputURL: first, option: option)
        case .video:
            return MediaEngines.convertVideo(inputURL: first, option: option, quality: videoQuality)
        case .webDownload:
            return .failure(ToolError.emptyInput)
        case .text:
            return MediaEngines.convertText(inputURL: first, option: option)
        case .spreadsheet:
            return MediaEngines.convertSpreadsheet(inputURL: first, option: option)
        case .image:
            return MediaEngines.convertImage(inputURLs: inputURLs, option: option)
        case .pdf:
            switch option.id {
            case "ocr_pdf":
                return PDFVisionEngine.ocrPDF(inputURL: first, option: option, languages: ocrLanguages, progress: progress)
            case "img_ocr_pdf":
                return PDFVisionEngine.imagesToOCRPDF(inputURLs: inputURLs, option: option, languages: ocrLanguages, progress: progress)
            case "ocr_txt":
                return PDFVisionEngine.extractOCRText(inputURL: first, languages: ocrLanguages, progress: progress)
            case "unlock":
                return PDFVisionEngine.unlockPDF(inputURL: first, option: option, password: password)
            case "merge":
                return PDFVisionEngine.mergePDFs(inputURLs: inputURLs, option: option)
            case "compress":
                return PDFVisionEngine.compressPDF(inputURL: first, option: option)
            default:
                return .failure(
                    ToolError.invalidInput(
                        L10n.t(
                            "Operação PDF desconhecida: \(option.id)",
                            en: "Unknown PDF operation: \(option.id)",
                            es: "Operación PDF desconocida: \(option.id)"
                        )
                    )
                )
            }
        }
    }

    func copyOutputToPasteboard(_ url: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([url as NSURL])
        copiedHint = true
    }

    func formattedFileSize(_ url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let bytes = attrs[.size] as? Int64 else {
            return ""
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
