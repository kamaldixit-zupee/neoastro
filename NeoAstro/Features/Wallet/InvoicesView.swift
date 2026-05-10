import SwiftUI

@Observable
@MainActor
final class InvoicesViewModel {
    var invoices: [Invoice] = []
    var isLoading: Bool = false
    var errorMessage: String?

    func load() async {
        guard invoices.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        AppLog.info(.wallet, "VM · invoices refresh start")
        do {
            invoices = try await WalletService.invoices()
            AppLog.info(.wallet, "VM · invoices refresh ok count=\(invoices.count)")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.wallet, "invoices fetch failed", error: error)
        }
        isLoading = false
    }
}

struct InvoicesView: View {
    @State private var vm = InvoicesViewModel()

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: 8) {
                    if vm.isLoading && vm.invoices.isEmpty {
                        ProgressView().tint(.white).controlSize(.large).padding(.top, 60)
                    } else if vm.invoices.isEmpty {
                        emptyState
                    } else {
                        ForEach(vm.invoices) { invoice in
                            row(invoice)
                        }
                    }
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .refreshable { await vm.refresh() }
        }
        .navigationTitle("Invoices")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await vm.load() }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.6))
                .padding(20)
                .glassEffect(.regular, in: .circle)
            Text(vm.errorMessage ?? "No invoices yet")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(vm.errorMessage == nil ? 0.65 : 0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func row(_ invoice: Invoice) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.goldGradient)
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(invoice.title ?? invoice.invoiceNumber ?? "Invoice")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let astro = invoice.astrologerName, !astro.isEmpty {
                    Text(astro)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
                if let issued = invoice.issuedDate, !issued.isEmpty {
                    Text(issued)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(invoice.displayAmount)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                if invoice.downloadUrl != nil {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.callout)
                        .foregroundStyle(AppTheme.pinkAccent)
                }
            }
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
