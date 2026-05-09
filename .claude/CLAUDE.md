# NeoAstro iOS – Claude Guide

This is the iOS user app for the NeoAstro astrology platform. The full agent contract lives in [AGENTS.md](../AGENTS.md); architectural detail is in [ARCHITECTURE.md](../ARCHITECTURE.md). Read those first.

## TL;DR for any change

- Swift 5.10 + SwiftUI, iOS 26 minimum, single XcodeGen target.
- MVVM with `@Observable @MainActor` ViewModels. **No Combine, no `ObservableObject`.**
- All HTTP goes through `APIClient.shared.send` – it owns auth, refresh, headers, envelope decoding.
- Tokens live in Keychain (`TokenStore`); nothing else is persisted.
- `print` is forbidden; use `AppLog.<category>`.
- `NeoAstro.xcodeproj/project.pbxproj` is generated – edit `project.yml` and run `xcodegen generate`.
- No third-party SDKs are installed. Adding one is a discussion, not a unilateral decision.

## Hard rules (do not break)

1. Don't `import Combine` or use `@Published` / `@StateObject` / `@EnvironmentObject` / `ObservableObject`. The codebase is all `@Observable`.
2. Don't bypass `APIClient` with bare `URLSession` calls – you'll lose token refresh.
3. Don't change `DeviceInfo.zupeeAppName` from `com.neoastro.android`. The Zupee gateway gates on it; "fixing" it 403s every request.
4. Don't drop any of the three envelope branches in `APIClient.send`. The backend uses all three.
5. Don't introduce caching (Core Data / SwiftData / file cache) without a real product requirement.
6. Don't change the bundle ID `varasol.MarathiCalendarPanchangam` casually – it's tied to provisioning.
7. Don't hand-edit `project.pbxproj`. Edit `project.yml`.

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

### New tab
Add a case to `AppTab` and a `Tab` entry in `MainTabView.swift`. Tint stays `AppTheme.pinkAccent`.

### New log category
Add it to `AppLog.swift`. Don't reuse a category that doesn't fit just to avoid the edit.
