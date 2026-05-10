import SwiftUI

struct PanchangView: View {
    @State private var vm = PanchangViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        if vm.isLoading && vm.panchang == nil {
                            ProgressView().tint(.white).controlSize(.large)
                                .padding(.top, 40)
                        } else if let error = vm.errorMessage, vm.panchang == nil {
                            errorView(error)
                        } else if let p = vm.panchang {
                            screenHeader(p)
                            ForEach(p.widgets ?? []) { widget in
                                widgetView(widget)
                            }
                            if let cta = p.cta, let text = cta.displayText, !text.isEmpty {
                                ctaButton(text: text)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
                .refreshable { await vm.refresh() }
            }
            .navigationTitle("Panchang")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task { await vm.load() }
        }
    }

    private func screenHeader(_ p: Panchang) -> some View {
        VStack(spacing: 6) {
            if let title = p.screenTitle, !title.isEmpty {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
            } else {
                Text(formattedToday())
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
            }
            if let subtitle = p.screenSubTitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            if let location = p.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(location)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(AppTheme.goldGradient)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect(.regular, in: .capsule)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func widgetView(_ widget: PanchangWidget) -> some View {
        switch widget {
        case .hero(let h):         heroWidget(h)
        case .sunMoon(let s):      sunMoonWidget(s)
        case .kaal(let k):         kaalWidget(k)
        case .chaughadiya(let c):  chaughadiyaWidget(c)
        case .nakshatra(let n):    nakshatraWidget(n)
        case .unknown:             EmptyView()
        }
    }

    private func heroWidget(_ h: PanchangWidget.Hero) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldGradient)
                    .frame(width: 130, height: 130)
                    .blur(radius: 30)
                    .opacity(0.55)

                if let urlString = h.moonFaceUrl ?? h.gifUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(AppTheme.goldGradient)
                    }
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .glassEffect(.regular, in: .circle)
                } else {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.goldGradient)
                        .frame(width: 110, height: 110)
                        .glassEffect(.regular, in: .circle)
                }
            }

            if let paksha = h.paksha, !paksha.isEmpty {
                Text(paksha)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }

            if let tithi = h.tithi {
                VStack(spacing: 4) {
                    if let name = tithi.tithiName, !name.isEmpty {
                        Text(name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    if let summary = tithi.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    if let endText = tithi.endTime?.displayText, !endText.isEmpty {
                        Text("until \(endText)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.goldGradient)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func sunMoonWidget(_ s: PanchangWidget.SunMoon) -> some View {
        let entries: [(label: String, icon: String, time: String?)] = [
            ("Sunrise",  "sunrise.fill",       s.sunrise?.time?.displayText),
            ("Sunset",   "sunset.fill",        s.sunset?.time?.displayText),
            ("Moonrise", "moon.fill",          s.moonrise?.time?.displayText),
            ("Moonset",  "moon.haze.fill",     s.moonset?.time?.displayText)
        ]

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(entries, id: \.label) { entry in
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: entry.icon)
                            .foregroundStyle(AppTheme.goldGradient)
                        Text(entry.label)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Text(entry.time ?? "—")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
            }
        }
    }

    private func kaalWidget(_ k: PanchangWidget.Kaal) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kaal")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(k.items ?? []) { item in
                    let segment = item.styles?.segmentColor.flatMap { Color(hex: $0) } ?? kaalColor(item.name)
                    let bg = item.styles?.backgroundColor.flatMap { Color(hex: $0).opacity(0.25) } ?? .white.opacity(0.05)

                    HStack(spacing: 12) {
                        Capsule()
                            .fill(segment)
                            .frame(width: 4, height: 44)

                        if let icon = item.iconUrl, let url = URL(string: icon) {
                            AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: {
                                Image(systemName: "clock.fill").foregroundStyle(segment)
                            }
                            .frame(width: 28, height: 28)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            if let start = item.startTime?.displayText, let end = item.endTime?.displayText {
                                Text("\(start) – \(end)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            } else if let start = item.startTime?.displayText {
                                Text(start)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(bg, in: .rect(cornerRadius: 16))
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }
            }
        }
    }

    private func chaughadiyaWidget(_ c: PanchangWidget.Chaughadiya) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = c.title, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            if let subtitle = c.subTitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(c.day ?? []) { d in
                        VStack(spacing: 4) {
                            Text(d.title ?? "")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(chaughadiyaColor(d.title))
                            Text(d.startTime?.displayText ?? "")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(width: 80)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: .rect(cornerRadius: 14))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func nakshatraWidget(_ n: PanchangWidget.Nakshatra) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(n.items ?? []) { item in
                if item.isTitle == true {
                    HStack(spacing: 10) {
                        if let icon = item.iconUrl, let url = URL(string: icon) {
                            AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: {
                                Image(systemName: "sparkles").foregroundStyle(AppTheme.goldGradient)
                            }
                            .frame(width: 28, height: 28)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title ?? item.tag?.name ?? "")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                            if let info = item.infoType {
                                Text(info)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(AppTheme.goldGradient)
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 4)
                } else {
                    nakshatraItemRow(item)
                }
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func nakshatraItemRow(_ item: PanchangNakshatraItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let icon = item.iconUrl, let url = URL(string: icon) {
                AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: {
                    Image(systemName: "sparkles").foregroundStyle(AppTheme.goldGradient)
                }
                .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let title = item.title, !title.isEmpty {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                if let summary = item.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                if let endText = item.endTime?.displayText, !endText.isEmpty {
                    Text("until \(endText)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()
        }
        .padding(10)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func ctaButton(text: String) -> some View {
        Button {} label: {
            Text(text)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .tint(AppTheme.pinkAccent)
    }

    private func kaalColor(_ name: String?) -> Color {
        switch (name ?? "").lowercased() {
        case let s where s.contains("rahu"): return .red
        case let s where s.contains("gulika"): return .orange
        case let s where s.contains("yamaganda"): return .pink
        case let s where s.contains("abhijit") || s.contains("amrit") || s.contains("brahma") || s.contains("vijaya"): return .green
        default: return .yellow
        }
    }

    private func chaughadiyaColor(_ title: String?) -> Color {
        switch (title ?? "").lowercased() {
        case "amrit", "shubh", "labh", "char": return .green
        case "kaal", "rog", "udveg": return .red
        default: return .white
        }
    }

    private func prettyKaal(_ key: String?) -> String {
        guard let key else { return "" }
        return key.replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private func formattedToday() -> String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: .now)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await vm.refresh() } }
                .buttonStyle(.glass)
                .tint(AppTheme.pinkAccent)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

#Preview {
    PanchangView()
        .previewEnvironment()
}
