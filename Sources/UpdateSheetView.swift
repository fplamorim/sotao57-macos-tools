import AppKit
import SwiftUI

struct UpdateSheetView: View {
    @ObservedObject private var vm = AppViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(red: 0.14, green: 0.36, blue: 0.72))
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        L10n.t(
                            "Atualizações no GitHub",
                            en: "GitHub Updates",
                            es: "Actualizaciones en GitHub"
                        )
                    )
                    .font(.headline)
                    Text(
                        L10n.t(
                            "Versão instalada: v\(L10n.appVersion)",
                            en: "Installed version: v\(L10n.appVersion)",
                            es: "Versión instalada: v\(L10n.appVersion)"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(
                L10n.t(
                    "Verificação 100% manual — este app nunca procura nem instala atualizações automaticamente em segundo plano.",
                    en: "100% manual check — this app never checks or installs updates automatically in the background.",
                    es: "Comprobación 100% manual — esta app nunca busca ni instala actualizaciones automáticamente."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Divider()

            statusContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()

            HStack {
                Button(L10n.t("Verificar novamente", en: "Check Again", es: "Comprobar de nuevo")) {
                    vm.runManualUpdateCheck()
                }
                .buttonStyle(.bordered)
                .disabled(vm.updateState == .checking)

                Spacer()

                Button(L10n.t("Fechar", en: "Close", es: "Cerrar")) {
                    vm.showingUpdateSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 480, height: 340)
        .background(Color(red: 0.97, green: 0.975, blue: 0.985))
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var statusContent: some View {
        switch vm.updateState {
        case .idle:
            EmptyView()
        case .checking:
            HStack(spacing: 10) {
                ProgressView()
                Text(
                    L10n.t(
                        "Consultando GitHub Releases…",
                        en: "Checking GitHub Releases…",
                        es: "Consultando GitHub Releases…"
                    )
                )
                .font(.subheadline)
            }
            .padding(.top, 12)

        case .upToDate(let current, let latest, let releaseURL):
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text(
                        L10n.t(
                            "Você já está usando a versão mais recente (v\(current)).",
                            en: "You are already on the latest version (v\(current)).",
                            es: "Ya estás usando la última versión (v\(current))."
                        )
                    )
                    .font(.subheadline.weight(.medium))
                }
                Text(
                    L10n.t(
                        "Último lançamento no GitHub: v\(latest)",
                        en: "Latest GitHub release: v\(latest)",
                        es: "Último lanzamiento en GitHub: v\(latest)"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Button(L10n.t("Abrir Releases no navegador", en: "Open Releases in Browser", es: "Abrir Releases en el navegador")) {
                    NSWorkspace.shared.open(releaseURL)
                }
                .controlSize(.small)
            }

        case .updateAvailable(let current, let latest, let notes, let dmgURL, let releaseURL):
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color(red: 0.14, green: 0.36, blue: 0.72))
                    Text(
                        L10n.t(
                            "Nova versão disponível: v\(latest) (atual: v\(current))",
                            en: "New version available: v\(latest) (current: v\(current))",
                            es: "Nueva versión disponible: v\(latest) (actual: v\(current))"
                        )
                    )
                    .font(.subheadline.weight(.semibold))
                }

                if !notes.isEmpty {
                    ScrollView {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(maxHeight: 96)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack(spacing: 10) {
                    if let dmg = dmgURL {
                        Button(L10n.t("Baixar instalador (.dmg)", en: "Download Installer (.dmg)", es: "Descargar instalador (.dmg)")) {
                            NSWorkspace.shared.open(dmg)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Button(L10n.t("Ver no GitHub", en: "View on GitHub", es: "Ver en GitHub")) {
                        NSWorkspace.shared.open(releaseURL)
                    }
                    .buttonStyle(.bordered)
                }
            }

        case .failed(let error):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(
                        L10n.t(
                            "Não foi possível verificar atualizações",
                            en: "Could not check for updates",
                            es: "No se pudieron comprobar actualizaciones"
                        )
                    )
                    .font(.subheadline.weight(.medium))
                }
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
