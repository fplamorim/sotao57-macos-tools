import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension ToolCategory {
    var tintColor: Color {
        switch self {
        case .audio: return Color(red: 0.09, green: 0.56, blue: 0.62)
        case .video: return Color(red: 0.78, green: 0.28, blue: 0.20)
        case .text: return Color(red: 0.22, green: 0.42, blue: 0.78)
        case .spreadsheet: return Color(red: 0.16, green: 0.58, blue: 0.36)
        case .image: return Color(red: 0.55, green: 0.35, blue: 0.76)
        case .pdf: return Color(red: 0.76, green: 0.43, blue: 0.12)
        }
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
        .frame(minWidth: 740, idealWidth: 780, maxWidth: 920, minHeight: 500, idealHeight: 530)
        .sheet(isPresented: $vm.showingDependencies) {
            DependenciesSheetView()
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
                    Text("SOTAO57 BASIC MAC TOOLS")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .tracking(0.5)
                    Text("Conversão rápida, OCR em PDF e utilitários locais no seu Mac")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    vm.refreshDependencies()
                    vm.showingDependencies = true
                } label: {
                    Label("Dependências", systemImage: "wrench.and.screwdriver")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Button {
                    vm.showingAbout = true
                } label: {
                    Label("Sobre · MIT", systemImage: "info.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 18)

            Divider()

            // Big Category Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(ToolCategory.allCases) { category in
                        CategoryCardButton(category: category) {
                            vm.openCategory(category)
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer
            HStack {
                Text("© 2026 Fernando Amorim · SOTAO57 · Licença MIT")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("100% offline · Salva sempre na mesma pasta do original")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }
}

struct CategoryCardButton: View {
    let category: ToolCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(category.tintColor.opacity(0.16))
                            .frame(width: 44, height: 44)
                        Image(systemName: category.symbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(category.tintColor)
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(category.tintColor.opacity(0.75))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(category.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
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
                    Label("Início", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
                .disabled(vm.isRunning)

                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(category.tintColor.opacity(0.16))
                        .frame(width: 30, height: 30)
                    Image(systemName: category.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(category.tintColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(category.title)
                        .font(.headline)
                    Text("SOTAO57 BASIC MAC TOOLS")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            // Main Split Area
            HStack(alignment: .top, spacing: 18) {
                dropZoneColumn
                    .frame(width: 280)

                rightOptionsColumn
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)

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
        }
    }

    private var actionButtonLabel: String {
        switch category {
        case .pdf:
            switch vm.selectedOption.id {
            case "unlock": return "Desbloquear"
            case "merge": return "Juntar PDFs"
            case "compress": return "Comprimir"
            default: return "Executar OCR"
            }
        default:
            return "Converter"
        }
    }

    private var dropZoneColumn: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(vm.isDropTargeted ? category.tintColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))

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

            Text(vm.selectedOption.supportsMultipleInputs ? "Arraste um ou mais arquivos aqui" : "Arraste o arquivo aqui")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(category.dropHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Escolher arquivo…") {
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
                Text("\(vm.inputURLs.count) arquivos selecionados")
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(vm.inputURLs.prefix(4).enumerated()), id: \.offset) { idx, u in
                        Text("\(idx + 1). \(u.lastPathComponent)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if vm.inputURLs.count > 4 {
                        Text("+ \(vm.inputURLs.count - 4) mais…")
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
                    Button("Adicionar…") {
                        vm.openFilePicker(append: true)
                    }
                    .controlSize(.small)
                } else {
                    Button("Trocar") {
                        vm.openFilePicker(append: false)
                    }
                    .controlSize(.small)
                }

                Button("Limpar") {
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
                Text(category == .pdf ? "Escolha a operação:" : "Converter para:")
                    .font(.headline)
                    .padding(.bottom, 2)

                ForEach(category.options) { opt in
                    radioRow(for: opt)
                }

                // Contextual extras
                if vm.selectedOption.usesOCR {
                    HStack(spacing: 8) {
                        Text("Idioma OCR:")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Picker("", selection: $vm.ocrLanguage) {
                            ForEach(OCRLanguagePreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 200)
                    }
                    .padding(.top, 6)
                }

                if category == .video && vm.selectedOption.id != "extract_mp3" && vm.selectedOption.id != "gif" {
                    HStack(spacing: 8) {
                        Text("Qualidade:")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Picker("", selection: $vm.videoQuality) {
                            ForEach(VideoQuality.allCases) { q in
                                Text(q.rawValue).tag(q)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 220)
                    }
                    .padding(.top, 6)
                }

                if vm.selectedOption.requiresPassword {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Senha do PDF (obrigatória para PDF encriptado):")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        SecureField("Digite a senha atual do PDF", text: $vm.pdfPassword)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 280)
                    }
                    .padding(.top, 6)
                }

                if let primary = vm.primaryInputURL {
                    let targetName = vm.selectedOption.outputURL(for: primary).lastPathComponent
                    Text("Saída: \(targetName) (na mesma pasta)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.top, 6)
                }
            }
            .padding(.trailing, 4)
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
                    .frame(width: 64, alignment: .leading)
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
            if vm.selectedOption.id == "merge" && vm.inputURLs.count < 2 {
                Text("Selecione pelo menos 2 PDFs para juntar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Selecione um arquivo e clique em \(actionButtonLabel).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .running(let msg):
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        case .success(let outputURL, let sizeText):
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Salvo: \(outputURL.lastPathComponent) (\(sizeText))")
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Button("Mostrar no Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                }
                .controlSize(.small)

                Button(vm.copiedHint ? "Copiado!" : "Copiar arquivo") {
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

// MARK: - Sheets

struct DependenciesSheetView: View {
    @ObservedObject private var vm = AppViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Motores e Dependências Locais")
                    .font(.headline)
                Spacer()
                Button("Atualizar") {
                    vm.refreshDependencies()
                }
                .controlSize(.small)
            }

            List(vm.dependencies) { dep in
                HStack(spacing: 10) {
                    Image(systemName: dep.isInstalled ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .foregroundStyle(dep.isInstalled ? .green : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dep.name)
                            .font(.system(size: 13, weight: .semibold))
                        Text(dep.purpose)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(dep.path ?? "Opcional · Instalar: \(dep.installHint)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 2)
            }
            .listStyle(.inset)

            HStack {
                Spacer()
                Button("Fechar") {
                    vm.showingDependencies = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 540, height: 420)
    }
}

struct AboutSheetView: View {
    @ObservedObject private var vm = AppViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SOTAO57 BASIC MAC TOOLS · v1.0.0")
                .font(.headline)
            Text("Copyright © 2026 Fernando Amorim (SOTAO57)")
                .font(.subheadline)
            Text("Suíte utilitária nativa para macOS para converter áudio, vídeo, texto, planilhas, imagens, executar OCR em PDF via Apple Vision e desbloquear PDFs protegidos com senha — tudo offline, na mesma pasta do arquivo original.")
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

            HStack {
                Link("GitHub (SOTAO57)", destination: URL(string: "https://github.com/fplamorim/sotao57-basic-mac-tools")!)
                    .font(.caption)
                Spacer()
                Button("Fechar") {
                    vm.showingAbout = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 520, height: 390)
    }
}
