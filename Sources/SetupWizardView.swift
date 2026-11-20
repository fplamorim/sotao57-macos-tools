import AppKit
import SwiftUI

struct SetupWizardView: View {
    @ObservedObject private var vm = AppViewModel.shared

    private var stepTitles: [String] {
        [
            L10n.t("1. Verificar", en: "1. Check", es: "1. Verificar"),
            L10n.t("2. Autorizar", en: "2. Authorize", es: "2. Autorizar"),
            L10n.t("3. Instalar", en: "3. Install", es: "3. Instalar"),
            L10n.t("4. Concluído", en: "4. Done", es: "4. Listo"),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            wizardHeader
            Divider()
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            wizardFooter
        }
        .background(Color(red: 0.97, green: 0.975, blue: 0.985))
        .frame(width: 620, height: 520)
        .preferredColorScheme(.light)
        .interactiveDismissDisabled(vm.wizardIsWorking)
    }

    private var wizardHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(red: 0.14, green: 0.36, blue: 0.72).opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.14, green: 0.36, blue: 0.72))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        L10n.t(
                            "Assistente de Configuração · SOTAO57 macOS Tools",
                            en: "Setup Wizard · SOTAO57 macOS Tools",
                            es: "Asistente de Configuración · SOTAO57 macOS Tools"
                        )
                    )
                    .font(.headline)
                    .foregroundStyle(.primary)
                    Text(
                        L10n.t(
                            "Verificação e instalação guiada dos motores de mídia e PDF neste Mac",
                            en: "Guided verification & installation of media and PDF engines on this Mac",
                            es: "Verificación e instalación guiada de los motores multimedia y PDF en este Mac"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    let isActive = vm.wizardStep.rawValue == index
                    let isDone = vm.wizardStep.rawValue > index
                    HStack(spacing: 5) {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "\(index + 1).circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(
                                isDone
                                    ? Color.green
                                    : (isActive ? Color(red: 0.14, green: 0.36, blue: 0.72) : Color.secondary.opacity(0.5))
                            )
                        Text(stepTitles[index])
                            .font(.caption.weight(isActive ? .semibold : .regular))
                            .foregroundStyle(isActive || isDone ? Color.primary : Color.secondary)
                    }
                    if index < 3 {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch vm.wizardStep {
        case .check:
            checkStepView
        case .selectAndAuth:
            selectAndAuthStepView
        case .installing:
            installingStepView
        case .done:
            doneStepView
        }
    }

    private var checkStepView: some View {
        let missing = vm.missingOptionalDependencies
        return VStack(alignment: .leading, spacing: 12) {
            if missing.isEmpty && vm.hasBrew {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                    Text(
                        L10n.t(
                            "Tudo pronto! Todas as dependências estão instaladas neste Mac.",
                            en: "All set! Every engine and dependency is already installed on this Mac.",
                            es: "¡Todo listo! Todas las dependencias ya están instaladas en este Mac."
                        )
                    )
                    .font(.subheadline.weight(.medium))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.orange)
                    Text(
                        L10n.t(
                            "Recursos nativos (Apple Vision OCR, Imagens e PDF) já funcionam. Motores extras abaixo habilitam MP3/Opus, Vídeo, Download Web, Markdown e PDF vetorial.",
                            en: "Native features (Apple Vision OCR, Images, PDF) work right away. Extra tools below enable MP3/Opus, Video, Web Download, Markdown & vector PDF unlock.",
                            es: "Las funciones nativas (Apple Vision OCR, Imágenes y PDF) ya funcionan. Las herramientas abajo habilitan MP3/Opus, Video, Descarga Web, Markdown y PDF vectorial."
                        )
                    )
                    .font(.caption)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            List {
                HStack(spacing: 10) {
                    Image(systemName: vm.hasBrew ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(vm.hasBrew ? .green : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Homebrew (macOS package manager)")
                            .font(.system(size: 12.5, weight: .semibold))
                        Text(
                            vm.hasBrew
                                ? L10n.t("Instalado e pronto para instalar motores", en: "Installed and ready to install tools", es: "Instalado y listo para instalar herramientas")
                                : L10n.t("Será instalado automaticamente no passo seguinte com autorização", en: "Will be installed automatically in the next step after authorization", es: "Se instalará automáticamente en el siguiente paso tras autorizar")
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    statusPill(installed: vm.hasBrew)
                }
                .padding(.vertical, 2)

                ForEach(vm.dependencies) { dep in
                    HStack(spacing: 10) {
                        Image(systemName: dep.isInstalled ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(dep.isInstalled ? .green : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dep.name)
                                .font(.system(size: 12.5, weight: .semibold))
                            Text(dep.purpose)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        statusPill(installed: dep.isInstalled, isNative: dep.isNative)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(18)
    }

    private var selectAndAuthStepView: some View {
        let missing = vm.missingOptionalDependencies
        let selectedCask = missing.contains { vm.selectedBrewPackages.contains($0.id) && $0.isCask }
        let needsPassword = !vm.hasBrew || selectedCask

        return VStack(alignment: .leading, spacing: 12) {
            Text(
                L10n.t(
                    "Selecione os pacotes que deseja instalar agora:",
                    en: "Select the packages you want to install now:",
                    es: "Selecciona los paquetes que deseas instalar ahora:"
                )
            )
            .font(.subheadline.weight(.semibold))

            if !vm.hasBrew {
                HStack(spacing: 8) {
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(Color(red: 0.14, green: 0.36, blue: 0.72))
                    Text(
                        L10n.t(
                            "O Homebrew também será instalado primeiro neste Mac.",
                            en: "Homebrew will also be installed first on this Mac.",
                            es: "Homebrew también se instalará primero en este Mac."
                        )
                    )
                    .font(.caption)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if missing.isEmpty && vm.hasBrew {
                Text(
                    L10n.t(
                        "Nenhum pacote pendente para instalar.",
                        en: "No pending packages to install.",
                        es: "No hay paquetes pendientes por instalar."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(missing) { dep in
                            let isOn = vm.selectedBrewPackages.contains(dep.id)
                            Button {
                                vm.toggleBrewPackage(dep.id)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: isOn ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 16))
                                        .foregroundStyle(isOn ? Color(red: 0.14, green: 0.36, blue: 0.72) : .secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(dep.name)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(.primary)
                                            Text(dep.installHint)
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(dep.purpose)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(isOn ? Color(red: 0.14, green: 0.36, blue: 0.72).opacity(0.45) : Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: needsPassword ? "lock.shield.fill" : "checkmark.shield.fill")
                    .foregroundStyle(Color(red: 0.14, green: 0.36, blue: 0.72))
                Text(
                    needsPassword
                        ? L10n.t(
                            "Ao clicar em «Autorizar e Instalar», o macOS abrirá a janela oficial pedindo a senha do seu Mac para autorizar a instalação.",
                            en: "When you click «Authorize & Install», macOS will display its native password prompt to authorize installation.",
                            es: "Al hacer clic en «Autorizar e Instalar», macOS mostrará su diálogo nativo pidiendo tu contraseña para autorizar."
                        )
                        : L10n.t(
                            "O Homebrew já está autorizado neste Mac. Clique em «Autorizar e Instalar» para iniciar a instalação dos pacotes selecionados.",
                            en: "Homebrew is already authorized on this Mac. Click «Authorize & Install» to install the selected packages.",
                            es: "Homebrew ya está autorizado en este Mac. Haz clic en «Autorizar e Instalar» para instalar los paquetes."
                        )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            if let err = vm.wizardAuthError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(18)
    }

    private var installingStepView: some View {
        let selectedDeps = vm.dependencies.filter { vm.selectedBrewPackages.contains($0.id) && !$0.isNative }
        let percent = Int((vm.wizardProgress * 100).rounded())

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(
                        vm.wizardCurrentPackage.isEmpty
                            ? L10n.t("Instalando dependências…", en: "Installing dependencies…", es: "Instalando dependencias…")
                            : vm.wizardCurrentPackage
                    )
                    .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(percent)%")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: vm.wizardProgress)
                    .progressViewStyle(.linear)
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(selectedDeps) { dep in
                        let st = vm.packageStates[dep.id] ?? .pending
                        HStack(spacing: 10) {
                            packageStatusIcon(st)
                            Text(dep.name)
                                .font(.system(size: 12.5, weight: .medium))
                            Spacer()
                            Text(packageStatusLabel(st))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                }
            }
            .frame(maxHeight: 150)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("Registro ao vivo:", en: "Live log:", es: "Registro en vivo:"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(vm.wizardLogLines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(8)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(18)
    }

    private var doneStepView: some View {
        let failedItems = vm.dependencies.compactMap { dep -> (DependencyStatus, String)? in
            if case .failed(let reason) = vm.packageStates[dep.id] {
                return (dep, reason)
            }
            return nil
        }

        return VStack(spacing: 12) {
            Spacer(minLength: 4)
            Image(systemName: vm.wizardFailedCount == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(vm.wizardFailedCount == 0 ? Color.green : Color.orange)

            Text(
                vm.wizardFailedCount == 0
                    ? L10n.t("Instalação concluída!", en: "Installation Complete!", es: "¡Instalación completada!")
                    : L10n.t("Instalação finalizada com avisos", en: "Installation Finished with Warnings", es: "Instalación finalizada con avisos")
            )
            .font(.title3.weight(.bold))

            Text(
                L10n.t(
                    "\(vm.wizardInstalledCount) pacote(s) instalado(s). Clique em «Concluir e Reiniciar App» para aplicar todas as ferramentas.",
                    en: "\(vm.wizardInstalledCount) package(s) installed. Click «Done & Restart App» to reload all engines cleanly.",
                    es: "\(vm.wizardInstalledCount) paquete(s) instalado(s). Haz clic en «Finalizar y Reiniciar App» para recargar todo."
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            if !failedItems.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(failedItems, id: \.0.id) { dep, reason in
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(dep.name)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.red)
                                Text(reason)
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                Text("Terminal: brew update && \(dep.installHint)")
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.14, green: 0.36, blue: 0.72))
                                    .textSelection(.enabled)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
                .frame(maxHeight: 150)
                .padding(.horizontal, 12)
            }

            Spacer(minLength: 4)
        }
        .padding(18)
    }

    @ViewBuilder
    private var wizardFooter: some View {
        HStack {
            switch vm.wizardStep {
            case .check:
                Button(L10n.t("Verificar novamente", en: "Re-check", es: "Volver a comprobar")) {
                    vm.recheckDependenciesInWizard()
                }
                .buttonStyle(.bordered)

                Spacer()

                if !vm.missingOptionalDependencies.isEmpty || !vm.hasBrew {
                    Button(L10n.t("Pular por agora", en: "Skip for now", es: "Omitir por ahora")) {
                        vm.finishWizardWithoutRestart()
                    }
                    .buttonStyle(.bordered)

                    Button(L10n.t("Avançar para Instalação →", en: "Continue to Install →", es: "Continuar a Instalación →")) {
                        vm.wizardStep = .selectAndAuth
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(L10n.t("Começar a usar", en: "Start Using App", es: "Comenzar a usar")) {
                        vm.finishWizardWithoutRestart()
                    }
                    .buttonStyle(.borderedProminent)
                }

            case .selectAndAuth:
                Button(L10n.t("← Voltar", en: "← Back", es: "← Volver")) {
                    vm.wizardStep = .check
                }
                .buttonStyle(.bordered)
                .disabled(vm.wizardIsWorking)

                Spacer()

                Button {
                    vm.startWizardInstall()
                } label: {
                    Label(
                        L10n.t("Autorizar e Instalar", en: "Authorize & Install", es: "Autorizar e Instalar"),
                        systemImage: "lock.open.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.wizardIsWorking || (vm.hasBrew && vm.selectedBrewPackages.isEmpty))

            case .installing:
                Text(
                    L10n.t(
                        "Aguarde enquanto as ferramentas são instaladas…",
                        en: "Please wait while dependencies are being installed…",
                        es: "Espera mientras se instalan las dependencias…"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()

            case .done:
                Button(L10n.t("Fechar", en: "Close", es: "Cerrar")) {
                    vm.finishWizardWithoutRestart()
                }
                .buttonStyle(.bordered)

                if vm.wizardFailedCount > 0 {
                    Button(L10n.t("Tentar novamente", en: "Retry", es: "Reintentar")) {
                        vm.recheckDependenciesInWizard()
                        let missingIDs = Set(vm.missingOptionalDependencies.map(\.id))
                        vm.selectedBrewPackages = vm.selectedBrewPackages.intersection(missingIDs)
                        vm.wizardStep = .selectAndAuth
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button {
                    vm.finishWizardAndRestart()
                } label: {
                    Label(
                        L10n.t("Concluir e Reiniciar App", en: "Done & Restart App", es: "Finalizar y Reiniciar App"),
                        systemImage: "arrow.clockwise.circle.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private func statusPill(installed: Bool, isNative: Bool = false) -> some View {
        let text: String
        let bg: Color
        let fg: Color
        if isNative && installed {
            text = L10n.t("Nativo", en: "Native", es: "Nativo")
            bg = Color.blue.opacity(0.12)
            fg = Color.blue
        } else if installed {
            text = L10n.t("Instalado", en: "Installed", es: "Instalado")
            bg = Color.green.opacity(0.14)
            fg = Color(red: 0.1, green: 0.52, blue: 0.22)
        } else {
            text = L10n.t("Ausente", en: "Missing", es: "Falta")
            bg = Color.orange.opacity(0.16)
            fg = Color(red: 0.72, green: 0.36, blue: 0.05)
        }
        return Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func packageStatusIcon(_ state: PackageInstallState) -> some View {
        switch state {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        case .installing:
            ProgressView()
                .controlSize(.small)
        case .installed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private func packageStatusLabel(_ state: PackageInstallState) -> String {
        switch state {
        case .pending:
            return L10n.t("Na fila", en: "Queued", es: "En cola")
        case .installing:
            return L10n.t("Instalando…", en: "Installing…", es: "Instalando…")
        case .installed:
            return L10n.t("Concluído", en: "Installed", es: "Instalado")
        case .failed(let msg):
            return msg
        }
    }
}
