import SwiftUI
import Observation

@Observable
@MainActor
final class HoroscopeViewModel {
    var horoscope: Horoscope?
    var type: HoroscopeService.HoroscopeType = .daily
    var isLoading: Bool = false
    var errorMessage: String?

    func load() async {
        guard horoscope == nil else { return }
        await refresh()
    }

    func change(type newType: HoroscopeService.HoroscopeType) async {
        guard newType != type else { return }
        type = newType
        await refresh()
    }

    func refresh() async {
        AppLog.info(.horoscope, "VM · refresh type=\(type.rawValue) sign=\(TokenStore.shared.zodiacName ?? "auto")")
        isLoading = true
        errorMessage = nil
        do {
            horoscope = try await HoroscopeService.fetch(type: type)
            AppLog.info(.horoscope, "VM · refresh success zodiac=\(horoscope?.zodiacName ?? "?") cards=\(horoscope?.horoscopeCards?.count ?? 0)")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            AppLog.error(.horoscope, "VM · refresh failed", error: error)
        }
        isLoading = false
    }
}
