import SwiftUI

@Observable
@MainActor
final class TransactionFilterViewModel {
    var typeFilters: [TransactionFilterOption] = []
    var dateFilters: [TransactionFilterOption] = []
    var isLoading: Bool = false
    var errorMessage: String?

    func load() async {
        guard typeFilters.isEmpty else { return }
        isLoading = true
        do {
            let result = try await WalletService.transactionFilters()
            typeFilters = result.filters ?? []
            dateFilters = result.dateRanges ?? []
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.wallet, "transaction filters fetch failed", error: error)
            // Hardcoded fallback so the sheet is still useful offline.
            typeFilters = [
                TransactionFilterOption(_id: "ALL",     label: "All",      value: "all"),
                TransactionFilterOption(_id: "CREDIT",  label: "Credits",  value: "credit"),
                TransactionFilterOption(_id: "DEBIT",   label: "Debits",   value: "debit"),
                TransactionFilterOption(_id: "DEPOSIT", label: "Deposits", value: "deposit"),
                TransactionFilterOption(_id: "CHAT",    label: "Chats",    value: "chat"),
                TransactionFilterOption(_id: "TDS",     label: "TDS",      value: "tds")
            ]
        }
        isLoading = false
    }
}

struct TransactionFilterSheet: View {
    @Binding var activeFilter: String?
    let onApply: (String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var vm = TransactionFilterViewModel()
    @State private var selectedValue: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    sectionHeader("Type")
                    chipFlow(vm.typeFilters)

                    if !vm.dateFilters.isEmpty {
                        sectionHeader("Date range")
                        chipFlow(vm.dateFilters)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            actionRow
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            selectedValue = activeFilter
            await vm.load()
        }
    }

    // MARK: - Components

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Filter transactions")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Narrow the passbook by type or date range.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white.opacity(0.55))
            .tracking(1)
    }

    private func chipFlow(_ options: [TransactionFilterOption]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { option in
                chip(option)
            }
        }
    }

    private func chip(_ option: TransactionFilterOption) -> some View {
        let isSelected = selectedValue == option.value
            || (option.value == "all" && selectedValue == nil)
        return Button {
            selectedValue = (option.value == "all") ? nil : option.value
        } label: {
            Text(option.label ?? option.value ?? "—")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glass)
        .tint(isSelected ? AppTheme.pinkAccent : .white.opacity(0.16))
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(role: .destructive) {
                selectedValue = nil
                onApply(nil)
                dismiss()
            } label: {
                Text("Clear")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glass)
            .tint(.white.opacity(0.18))

            Button {
                onApply(selectedValue)
                dismiss()
            } label: {
                Text("Apply")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(AppTheme.pinkAccent)
        }
    }
}

// MARK: - FlowLayout

/// Minimal flowing-chip layout. Wraps to the next row when a chip wouldn't
/// fit. Keeps the filter sheet from forcing a fixed-column grid.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > containerWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x)
        }
        return CGSize(width: maxX, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        let maxX = bounds.maxX

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y),
                      proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
