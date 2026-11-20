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

    @Published var activeCategory: ToolCategory? = nil
    @Published var inputURLs: [URL] = []
    @Published var selectedOption: ToolOption = ToolCategory.audio.options[0]
    @Published var ocrLanguage: OCRLanguagePreset = .ptEn
    @Published var videoQuality: VideoQuality = .balanced
    @Published var pdfPassword: String = ""
    @Published var operationState: OperationState = .idle
    @Published var isDropTargeted: Bool = false
    @Published var copiedHint: Bool = false

    @Published var showingDependencies: Bool = false
    @Published var showingAbout: Bool = false
    @Published var dependencies: [DependencyStatus] = []

    var primaryInputURL: URL? { inputURLs.first }

    var isRunning: Bool {
        if case .running = operationState { return true }
        return false
    }

    var canExecute: Bool {
        guard !isRunning, !inputURLs.isEmpty else { return false }
        if selectedOption.id == "merge" && inputURLs.count < 2 {
            return false
        }
        return true
    }

    func openCategory(_ category: ToolCategory) {
        activeCategory = category
        inputURLs = []
        selectedOption = category.options[0]
        pdfPassword = ""
        operationState = .idle
        copiedHint = false
    }

    func goHome() {
        guard !isRunning else { return }
        activeCategory = nil
        inputURLs = []
        pdfPassword = ""
        operationState = .idle
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
        copiedHint = false

        // Smart default: pick a different output extension if single input matches current target
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
        guard let cat = activeCategory else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = selectedOption.supportsMultipleInputs
        panel.message = selectedOption.supportsMultipleInputs
            ? "Selecione um ou mais ficheiros"
            : "Escolha o ficheiro para processar"

        let allowed = cat.acceptedExtensions.compactMap { UTType(filenameExtension: $0) }
        if !allowed.isEmpty {
            panel.allowedContentTypes = allowed
        }

        if panel.runModal() == .OK {
            setFiles(panel.urls, append: append)
        }
    }

    func handleDrop(providers: [NSItemProvider]) -> Bool {
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

    func refreshDependencies() {
        dependencies = ShellRunner.checkDependencies()
    }

    func executeActiveTool() {
        guard let cat = activeCategory, !inputURLs.isEmpty else { return }
        let option = selectedOption
        let files = inputURLs
        let langCodes = ocrLanguage.codes
        let vidQuality = videoQuality
        let pwd = pdfPassword

        copiedHint = false
        operationState = .running("Processando \(option.title)…")

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Self.dispatchConversion(
                category: cat,
                option: option,
                inputURLs: files,
                ocrLanguages: langCodes,
                videoQuality: vidQuality,
                password: pwd,
                progress: { msg in
                    DispatchQueue.main.async {
                        self.operationState = .running(msg)
                    }
                }
            )

            DispatchQueue.main.async {
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
        progress: ((String) -> Void)?
    ) -> Result<URL, Error> {
        guard let first = inputURLs.first else {
            return .failure(ToolError.emptyInput)
        }
        switch category {
        case .audio:
            return MediaEngines.convertAudio(inputURL: first, option: option)
        case .video:
            return MediaEngines.convertVideo(inputURL: first, option: option, quality: videoQuality)
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
                return .failure(ToolError.invalidInput("Operação PDF desconhecida: \(option.id)"))
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
