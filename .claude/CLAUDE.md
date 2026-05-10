# NeoAstro iOS – Claude Guide

This is the iOS user app for the NeoAstro astrology platform. The full agent contract lives in [AGENTS.md](../AGENTS.md); architectural detail is in [ARCHITECTURE.md](../ARCHITECTURE.md). Read those first.

## TL;DR for any change

- Swift 5.10 + SwiftUI, iOS 26 minimum, single XcodeGen target.
- MVVM with `@Observable @MainActor` ViewModels. **No Combine, no `ObservableObject`.**
- All HTTP goes through `APIClient.shared.send` – it owns auth, refresh, headers, envelope decoding.
- All realtime goes through `NeoAstroSocket.shared` (Socket.IO actor) – `emit` for fire-and-forget, `emitWithAck` for messages that must not silently drop.
- Tokens live in Keychain (`TokenStore`); language + onboarding flag also persist there. Nothing else.
- `print` is forbidden; use `AppLog.<category>`.
- `NeoAstro.xcodeproj/project.pbxproj` is generated – edit `project.yml` and run `xcodegen generate`. Re-run after adding new source files.
- One third-party SDK today (`socket.io-client-swift`). Adding another (Agora, Sentry, etc.) is a discussion, not a unilateral decision.
- Liquid Glass for chrome / modals; `.sheet` / `.fullScreenCover` for modals — never hand-rolled overlays with opaque backgrounds.

## Hard rules (do not break)

1. Don't `import Combine` or use `@Published` / `@StateObject` / `@EnvironmentObject` / `ObservableObject`. The codebase is all `@Observable`.
2. Don't bypass `APIClient` with bare `URLSession` calls – you'll lose token refresh.
3. Don't bypass `NeoAstroSocket` with raw Socket.IO client calls – you'll lose the envelope codec, validation guards, ack-retry, and reconnect policy.
4. Don't change `DeviceInfo.zupeeAppName` (or the matching socket-handshake `packageName`) from `com.neoastro.android`. The Zupee gateway gates on it; "fixing" it 403s every request.
5. Don't drop any of the three envelope branches in `APIClient.send`. The backend uses all three.
6. Don't introduce caching (Core Data / SwiftData / file cache) without a real product requirement.
7. Don't change the bundle ID `varasol.MarathiCalendarPanchangam` casually – it's tied to provisioning.
8. Don't hand-edit `project.pbxproj`. Edit `project.yml`.
9. Don't add a second third-party SDK without explicit alignment. Socket.IO was approved; the next isn't pre-approved.

## Routing

This repo is small enough that direct `Read` / `Edit` is almost always the right tool. Use the `Explore` agent only when a question genuinely spans 3+ files you can't predict.

If the task is about the Zupee backend services or the React Native apps, you're in the wrong repo – switch to `/Users/kamal.dixit/Desktop/neoastro-root` and follow its `AGENTS.md`.

## Tone for this repo

- Default to terse, file-path-anchored answers. The user is an experienced iOS engineer.
- When suggesting changes, reference the existing pattern (`like HomeViewModel does`) rather than inventing new abstractions.
- If a request would require breaking one of the hard rules, push back with the rule and the reason before doing it.

## Recipes

### New feature
`Features/<Name>/{<Name>View.swift, <Name>ViewModel.swift}` + `Models/API/<Name>API.swift` + `Services/<Name>Service.swift`. ViewModel is `@Observable @MainActor final class` with `async` methods. View owns it via `@State private var vm = <Name>ViewModel()`.

### New endpoint
DTO in `Models/API/`, call in `Services/<Name>Service.swift` via `APIClient.shared.send(Request(...), as: T.self)`. Don't touch `APIClient` itself.

### New socket event
1. Add the case to `Realtime/SocketEvent.swift` (preserve server casing including any typos like `ANSWER_VIEWD`).
2. Add the typed payload to `Realtime/Models/RealtimeEvents.swift`.
3. If server→client, route through the right handler under `Realtime/handlers/` and surface domain state on `RealtimeStore`.
4. If client→server, emit via `NeoAstroSocket.shared.emit(_:payload:)` (or `emitWithAck` for must-deliver messages).

### New tab
Add a case to `AppTab` and a `Tab` entry in `MainTabView.swift`. Tint stays `AppTheme.pinkAccent`.

### New deep link
Add the case to `DeepLinkRouter.Intent` and the URL parsing branch. Decide which view consumes it (`MainTabView` for tab switches, then `HomeView` / `WalletView` / etc. for the screen-level state).

### New log category
Add it to `AppLog.swift`. Don't reuse a category that doesn't fit just to avoid the edit.
