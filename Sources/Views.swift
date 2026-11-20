import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension ToolCategory {
    var tintColor: Color {
        switch self {
        case .audio: return Color(red: 0.09, green: 0.56, blue: 0.62)
        case .video: return Color(red: 0.78, green: 0.28, blue: 0.20)
        case .webDownload: return Color(red: 0.80, green: 0.16, blue: 0.44)
        case .text: return Color(red: 0.22, green: 0.42, blue: 0.78)
        case .spreadsheet: return Color(red: 0.16, green: 0.58, blue: 0.36)
        case .image: return Color(red: 0.55, green: 0.35, blue: 0.76)
        case .pdf: return Color(red: 0.76, green: 0.43, blue: 0.12)
        }
    }

    static var gridCategories: [ToolCategory] {
        [.audio, .video, .webDownload, .text, .spreadsheet, .image]
    }
}

struct RootView: View {
    @ObservedObject private var vm = AppViewModel.shared

    var body: some View {
        Group {
            if let category = vm.activeCategory {
                ToolWorkspaceView(category: category)
            } else {
                HomeHubView()
            }
        }
        .background(Color(red: 0.96, green: 0.965, blue: 0.975))
        .frame(minWidth: 780, idealWidth: 830, maxWidth: 960, minHeight: 550, idealHeight: 585)
        .preferredColorScheme(.light)
        .sheet(isPresented: $vm.showingSetupWizard) {
            SetupWizardView()
        }
        .sheet(isPresented: $vm.showingUpdateSheet) {
            UpdateSheetView()
        }
        .sheet(isPresented: $vm.showingAbout) {
            AboutSheetView()
        }
    }
}

// MARK: - Home Hub

struct HomeHubView: View {
    @ObservedObject private var vm = AppViewModel.shared

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.11, green: 0.15, blue: 0.36), Color(red: 0.74, green: 0.22, blue: 0.16)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Text("57")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("SOTAO57 macOS Tools")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.10, green: 0.12, blue: 0.18))
                    Text(
                        L10n.t(
                            "Conversão rápida, download da Web, OCR em PDF e utilitários locais no seu Mac",
                            en: "Fast file conversion, web media downloads, Apple Vision PDF OCR & local Mac tools",
                            es: "Conversión rápida, descarga Web, OCR en PDF y utilidades locales en tu Mac"
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    vm.openSetupWizard()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "wrench.and.screwdriver")
                        Text(L10n.t("Dependências", en: "Dependencies", es: "Dependencias"))
                        if vm.missingCoreDependenciesCount > 0 {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 7, height: 7)
                        }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button {
                    vm.openUpdateCheckerAndRun()
                } label: {
                    Label(
                        L10n.t("Atualizações", en: "Updates", es: "Actualizaciones"),
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button {
                    vm.showingAbout = true
                } label: {
                    Label(L10n.t("Sobre", en: "About", es: "Acerca de"), systemImage: "info.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color.white)

            Divider()

            // Big Category Grid (6 tiles) + Full-width PDF Banner
            ScrollView {
                VStack(spacing: 14) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(ToolCategory.gridCategories) { category in
                            CategoryCardButton(category: category) {
                                vm.openCategory(category)
                            }
                        }
                    }

                    FeaturedPDFCardButton(category: .pdf) {
                        vm.openCategory(.pdf)
                    }
                }
                .padding(22)
            }
            .background(Color(red: 0.96, green: 0.965, blue: 0.975))

            Divider()

            // Footer
            HStack {
                Text(
                    L10n.t(
                        "© 2026 Fernando Amorim · SOTAO57 · Licença MIT",
                        en: "© 2026 Fernando Amorim · SOTAO57 · MIT License",
                        es: "© 2026 Fernando Amorim · SOTAO57 · Licencia MIT"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                Text(
                    L10n.t(
                        "Processamento local · Salva sempre na mesma pasta do original",
                        en: "Local processing · Saves right beside your original file",
                        es: "Procesamiento local · Guarda siempre junto al archivo original"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 11)
            .background(Color.white)
        }
    }
}

struct CategoryCardButton: View {
    let category: ToolCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(category.tintColor.opacity(0.14))
                            .frame(width: 42, height: 42)
                        Image(systemName: category.symbol)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(category.tintColor)
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(category.tintColor.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.10, green: 0.12, blue: 0.18))
                        .lineLimit(1)

                    Text(category.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 5, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(category.tintColor.opacity(0.28), lineWidth: 1.2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FeaturedPDFCardButton: View {
    let category: ToolCategory
    let action: () -> Void

    private var badges: [String] {
        [
            "Apple Vision OCR",
            L10n.t("Imagem → PDF OCR", en: "Image → OCR PDF", es: "Imagen → PDF OCR"),
            L10n.t("Desbloquear c/ senha", en: "Password Unlock", es: "Desbloquear c/ clave"),
            L10n.t("Juntar PDFs", en: "Merge PDFs", es: "Unir PDFs"),
            L10n.t("Comprimir", en: "Compress", es: "Comprimir"),
        ]
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(category.tintColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: category.symbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(category.tintColor)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(category.title)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(Color(red: 0.10, green: 0.12, blue: 0.18))
                    HStack(spacing: 6) {
                        ForEach(badges, id: \.self) { label in
                            Text(label)
                                .font(.system(size: 10.5, weight: .medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(category.tintColor.opacity(0.10))
                                .foregroundStyle(category.tintColor)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(category.tintColor.opacity(0.85))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 5, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(category.tintColor.opacity(0.32), lineWidth: 1.2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tool Workspace

struct ToolWorkspaceView: View {
    let category: ToolCategory
    @ObservedObject private var vm = AppViewModel.shared

    var body: some View {
        VStack(spacing: 0) {
            // Top bar with Back button
            HStack(spacing: 12) {
                Button {
                    vm.goHome()
                } label: {
                    Label(L10n.t("Início", en: "Home", es: "Inicio"), systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
                .disabled(vm.isRunning)

                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(category.tintColor.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: category.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(category.tintColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(category.title)
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.10, green: 0.12, blue: 0.18))
                    Text("SOTAO57 macOS Tools")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)

            Divider()

            // Main Split Area
            HStack(alignment: .top, spacing: 18) {
                if category == .webDownload {
                    webDownloadInputColumn
                        .frame(width: 300)
                } else {
                    dropZoneColumn
                        .frame(width: 290)
                }

                rightOptionsColumn
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .background(Color(red: 0.96, green: 0.965, blue: 0.975))

            Divider()

            // Bottom Execution Bar
            HStack(spacing: 12) {
                statusBanner
                Spacer(minLength: 8)
                Button(actionButtonLabel) {
                    vm.executeActiveTool()
                }
                .buttonStyle(.borderedProminent)
                .tint(category.tintColor)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!vm.canExecute)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
        }
    }

    private var actionButtonLabel: String {
        switch category {
        case .webDownload:
            return L10n.t("Baixar", en: "Download", es: "Descargar")
        case .pdf:
            switch vm.selectedOption.id {
            case "unlock": return L10n.t("Desbloquear", en: "Unlock", es: "Desbloquear")
            case "merge": return L10n.t("Juntar PDFs", en: "Merge PDFs", es: "Unir PDFs")
            case "compress": return L10n.t("Comprimir", en: "Compress", es: "Comprimir")
            default: return L10n.t("Executar OCR", en: "Run OCR", es: "Ejecutar OCR")
            }
        default:
            return L10n.t("Converter", en: "Convert", es: "Convertir")
        }
    }

    private var webDownloadInputColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    L10n.t("Link do vídeo ou áudio", en: "Video or audio link", es: "Enlace del video o audio"),
                    systemImage: "link"
                )
                .font(.headline)

                TextField("https://www.youtube.com/watch?v=...", text: $vm.webURL)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    Button(L10n.t("Colar link", en: "Paste URL", es: "Pegar enlace")) {
                        vm.pasteWebURL()
                    }
                    .controlSize(.small)

                    if !vm.webURL.isEmpty {
                        Button(L10n.t("Limpar", en: "Clear", es: "Limpiar")) {
                            vm.clearWebURL()
                        }
                        .controlSize(.small)
                    }
                }

                Text(
                    L10n.t(
                        "Compatível com links públicos do YouTube, TikTok, LinkedIn, Instagram, X, Vimeo e centenas de outros sites.",
                        en: "Supports public links from YouTube, TikTok, LinkedIn, Instagram, X, Vimeo and hundreds of other sites.",
                        es: "Compatible con enlaces públicos de YouTube, TikTok, LinkedIn, Instagram, X, Vimeo y cientos de sitios."
                    )
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 8) {
                Label(
                    L10n.t("Pasta de destino", en: "Save folder", es: "Carpeta de destino"),
                    systemImage: "folder"
                )
                .font(.subheadline.weight(.semibold))

                Text(vm.downloadDirectory.path)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)

                Button(L10n.t("Escolher pasta…", en: "Choose folder…", es: "Elegir carpeta…")) {
                    vm.pickDownloadDirectory()
                }
                .controlSize(.small)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            )

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
    }

    private var dropZoneColumn: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(vm.isDropTargeted ? category.tintColor.opacity(0.10) : Color.white)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    vm.isDropTargeted ? category.tintColor : Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 2, dash: [7, 5])
                )

            if vm.inputURLs.isEmpty {
                emptyDropPrompt
                    .padding(16)
            } else {
                selectedFilesSummary
                    .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [UTType.fileURL], isTargeted: $vm.isDropTargeted) { providers in
            vm.handleDrop(providers: providers)
        }
    }

    private var emptyDropPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: category.symbol)
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(category.tintColor.opacity(0.85))

            Text(
                vm.selectedOption.supportsMultipleInputs
                    ? L10n.t("Arraste um ou mais arquivos aqui", en: "Drop one or more files here", es: "Arrastra uno o más archivos aquí")
                    : L10n.t("Arraste o arquivo aqui", en: "Drop file here", es: "Arrastra el archivo aquí")
            )
            .font(.headline)
            .multilineTextAlignment(.center)

            Text(category.dropHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(L10n.t("Escolher arquivo…", en: "Choose file…", es: "Elegir archivo…")) {
                vm.openFilePicker(append: false)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .padding(.top, 4)
        }
    }

    private var selectedFilesSummary: some View {
        let first = vm.inputURLs[0]
        let ext = first.pathExtension.uppercased()
        let folderName = first.deletingLastPathComponent().lastPathComponent

        return VStack(spacing: 10) {
            Image(systemName: vm.inputURLs.count > 1 ? "doc.on.doc.fill" : "doc.richtext")
                .font(.system(size: 30))
                .foregroundStyle(category.tintColor)

            if vm.inputURLs.count == 1 {
                Text(first.lastPathComponent)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                HStack(spacing: 6) {
                    if !ext.isEmpty {
                        Text(ext)
                            .font(.caption2.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(category.tintColor.opacity(0.15))
                            .foregroundStyle(category.tintColor)
                            .clipShape(Capsule())
                    }
                    let sz = vm.formattedFileSize(first)
                    if !sz.isEmpty {
                        Text(sz)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(
                    L10n.t(
                        "\(vm.inputURLs.count) arquivos selecionados",
                        en: "\(vm.inputURLs.count) files selected",
                        es: "\(vm.inputURLs.count) archivos seleccionados"
                    )
                )
                .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(vm.inputURLs.prefix(4).enumerated()), id: \.offset) { idx, u in
                        Text("\(idx + 1). \(u.lastPathComponent)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if vm.inputURLs.count > 4 {
                        Text(
                            L10n.t(
                                "+ \(vm.inputURLs.count - 4) mais…",
                                en: "+ \(vm.inputURLs.count - 4) more…",
                                es: "+ \(vm.inputURLs.count - 4) más…"
                            )
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.caption2)
                Text(folderName)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                if vm.selectedOption.supportsMultipleInputs {
                    Button(L10n.t("Adicionar…", en: "Add…", es: "Añadir…")) {
                        vm.openFilePicker(append: true)
                    }
                    .controlSize(.small)
                } else {
                    Button(L10n.t("Trocar", en: "Change", es: "Cambiar")) {
                        vm.openFilePicker(append: false)
                    }
                    .controlSize(.small)
                }

                Button(L10n.t("Limpar", en: "Clear", es: "Limpiar")) {
                    vm.clearFiles()
                }
                .controlSize(.small)
            }
            .padding(.top, 4)
        }
    }

    private var rightOptionsColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                Text(
                    category == .pdf
                        ? L10n.t("Escolha a operação:", en: "Choose operation:", es: "Elige la operación:")
                        : (category == .webDownload
                            ? L10n.t("Formato de download:", en: "Download format:", es: "Formato de descarga:")
                            : L10n.t("Converter para:", en: "Convert to:", es: "Convertir a:"))
                )
                .font(.headline)
                .padding(.bottom, 2)

                ForEach(category.options) { opt in
                    radioRow(for: opt)
                }

                if vm.selectedOption.usesOCR {
                    HStack(spacing: 8) {
                        Text(L10n.t("Idioma OCR:", en: "OCR Language:", es: "Idioma OCR:"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Picker("", selection: $vm.ocrLanguage) {
                            ForEach(OCRLanguagePreset.allCases) { preset in
                                Text(preset.displayName).tag(preset)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 210)
                    }
                    .padding(.top, 6)
                }

                if category == .video && vm.selectedOption.id != "extract_mp3" && vm.selectedOption.id != "gif" {
                    HStack(spacing: 8) {
                        Text(L10n.t("Qualidade:", en: "Quality:", es: "Calidad:"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Picker("", selection: $vm.videoQuality) {
                            ForEach(VideoQuality.allCases) { q in
                                Text(q.displayName).tag(q)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 230)
                    }
                    .padding(.top, 6)
                }

                if vm.selectedOption.requiresPassword {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(
                            L10n.t(
                                "Senha do PDF (obrigatória para PDF encriptado):",
                                en: "PDF password (required for encrypted PDFs):",
                                es: "Contraseña del PDF (requerida para PDF cifrado):"
                            )
                        )
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        SecureField(
                            L10n.t("Digite a senha atual do PDF", en: "Enter current PDF password", es: "Ingresa la contraseña actual"),
                            text: $vm.pdfPassword
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 280)
                    }
                    .padding(.top, 6)
                }

                if category != .webDownload, let primary = vm.primaryInputURL {
                    let targetName = vm.selectedOption.outputURL(for: primary).lastPathComponent
                    Text(
                        L10n.t(
                            "Saída: \(targetName) (na mesma pasta)",
                            en: "Output: \(targetName) (in the same folder)",
                            es: "Salida: \(targetName) (en la misma carpeta)"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.top, 6)
                }
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func radioRow(for opt: ToolOption) -> some View {
        let isSelected = vm.selectedOption.id == opt.id
        return Button {
            vm.selectOption(opt)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? category.tintColor : Color.secondary)

                Text(opt.badge)
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .frame(width: 66, alignment: .leading)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(opt.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(opt.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? category.tintColor.opacity(0.11) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch vm.operationState {
        case .idle:
            if category == .webDownload {
                Text(
                    L10n.t(
                        "Cole o link acima, escolha o formato e clique em \(actionButtonLabel).",
                        en: "Paste a URL above, choose a format and click \(actionButtonLabel).",
                        es: "Pega un enlace arriba, elige el formato y haz clic en \(actionButtonLabel)."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else if vm.selectedOption.id == "merge" && vm.inputURLs.count < 2 {
                Text(
                    L10n.t(
                        "Selecione pelo menos 2 PDFs para juntar.",
                        en: "Select at least 2 PDFs to merge.",
                        es: "Selecciona al menos 2 PDFs para unir."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Text(
                    L10n.t(
                        "Selecione um arquivo e clique em \(actionButtonLabel).",
                        en: "Select a file and click \(actionButtonLabel).",
                        es: "Selecciona un archivo y haz clic en \(actionButtonLabel)."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        case .running(let msg):
            HStack(spacing: 8) {
                if let frac = vm.operationProgress {
                    ProgressView(value: frac)
                        .progressViewStyle(.linear)
                        .frame(width: 110)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        case .success(let outputURL, let sizeText):
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(
                    L10n.t(
                        "Salvo: \(outputURL.lastPathComponent) (\(sizeText))",
                        en: "Saved: \(outputURL.lastPathComponent) (\(sizeText))",
                        es: "Guardado: \(outputURL.lastPathComponent) (\(sizeText))"
                    )
                )
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .truncationMode(.middle)

                Button(L10n.t("Mostrar no Finder", en: "Show in Finder", es: "Mostrar en Finder")) {
                    NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                }
                .controlSize(.small)

                Button(
                    vm.copiedHint
                        ? L10n.t("Copiado!", en: "Copied!", es: "¡Copiado!")
                        : L10n.t("Copiar arquivo", en: "Copy file", es: "Copiar archivo")
                ) {
                    vm.copyOutputToPasteboard(outputURL)
                }
                .controlSize(.small)
            }
        case .error(let msg):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - About Sheet

struct AboutSheetView: View {
    @ObservedObject private var vm = AppViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SOTAO57 macOS Tools · v\(L10n.appVersion)")
                .font(.headline)
            Text("Copyright © 2026 Fernando Amorim (SOTAO57)")
                .font(.subheadline)
            Text(
                L10n.t(
                    "Suíte utilitária nativa para macOS para converter áudio, vídeo, baixar mídia da Web (yt-dlp), texto, planilhas, imagens, executar OCR em PDF via Apple Vision e desbloquear PDFs com senha.",
                    en: "Native macOS utility suite for converting audio, video, downloading web media (yt-dlp), text, spreadsheets, images, running Apple Vision PDF OCR and unlocking password-protected PDFs.",
                    es: "Suite nativa para macOS para convertir audio, video, descargar medios Web (yt-dlp), texto, hojas de cálculo, imágenes, ejecutar OCR con Apple Vision y desbloquear PDFs con contraseña."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()

            ScrollView {
                Text("""
                MIT License

                Copyright (c) 2026 Fernando Amorim (SOTAO57)

                Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                """)
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            }
            .padding(8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack {
                Link("GitHub (SOTAO57)", destination: L10n.repoURL)
                    .font(.caption)
                Spacer()
                Button(L10n.t("Fechar", en: "Close", es: "Cerrar")) {
                    vm.showingAbout = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 520, height: 390)
        .background(Color(red: 0.97, green: 0.975, blue: 0.985))
        .preferredColorScheme(.light)
    }
}
