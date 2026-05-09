import SwiftUI

@Observable
@MainActor
final class TDSViewModel {
    var info: UserTDSInfo?
    var certificates: [TDSCertificate] = []
    var isLoading: Bool = false
    var errorMessage: String?

    func load() async {
        guard certificates.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        AppLog.info(.wallet, "VM · TDS refresh start")
        async let infoTask = fetchInfo()
        async let certsTask = fetchCertificates()
        _ = await [infoTask, certsTask]
        isLoading = false
        AppLog.info(.wallet, "VM · TDS refresh done certs=\(certificates.count)")
    }

    private func fetchInfo() async {
        do {
            info = try await WalletService.userTDSInfo()
        } catch {
            AppLog.error(.wallet, "userTDSInfo failed", error: error)
        }
    }

    private func fetchCertificates() async {
        do {
            certificates = try await WalletService.tdsCertificates()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.wallet, "tdsCertificates failed", error: error)
        }
    }
}

struct TDSView: View {
    @State private var vm = TDSViewModel()

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    if let info = vm.info {
                        summaryCard(info)
                    }

                    certificatesSection

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .refreshable { await vm.refresh() }
        }
        .navigationTitle("TDS")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await vm.load() }
    }

    private func summaryCard(_ info: UserTDSInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Total TDS deducted")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.65))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("₹")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(Int(info.totalTdsDeducted ?? 0))")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.goldGradient)
            }

            HStack(spacing: 10) {
                if let pan = info.panMasked ?? info.panNumber {
                    pill(icon: "doc.text.fill", text: pan)
                }
                if let fy = info.financialYear, !fy.isEmpty {
                    pill(icon: "calendar", text: "FY \(fy)")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.cardCorner))
    }

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.goldGradient)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }

    @ViewBuilder
    private var certificatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Certificates")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if vm.isLoading && !vm.certificates.isEmpty {
                    ProgressView().tint(.white)
                }
            }
            .padding(.horizontal, 4)

            if vm.isLoading && vm.certificates.isEmpty {
                ProgressView().tint(.white).controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if vm.certificates.isEmpty {
                Text(vm.errorMessage ?? "No TDS certificates yet.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(vm.errorMessage == nil ? 0.65 : 0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                    .glassEffect(.regular, in: .rect(cornerRadius: 18))
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.certificates) { cert in
                        certificateRow(cert)
                    }
                }
            }
        }
    }

    private func certificateRow(_ cert: TDSCertificate) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.goldGradient)
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(cert.displayLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("₹\(cert.displayAmount) deducted")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            if cert.downloadUrl != nil {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.pinkAccent)
            }
        }
        .padding(12)
        .contentShape(Rectangle())
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
