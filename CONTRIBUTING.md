# Contributing to NeoAstro iOS

This is the native iOS user app for the NeoAstro astrology platform. Before you start, skim [ARCHITECTURE.md](ARCHITECTURE.md) for the structural overview and [AGENTS.md](AGENTS.md) for the hard rules.

## Prerequisites

| Tool | Version | Why |
|------|---------|-----|
| Xcode | 26.x or later | Builds the iOS 26 deployment target |
| Swift | 5.10 (bundled) | Source compatibility |
| XcodeGen | latest (`brew install xcodegen`) | Regenerates `NeoAstro.xcodeproj` |
| Apple Developer team | `H5YRX72888` | Code signing (already pinned in `project.yml`) |

There are **no Swift Package or CocoaPods dependencies**. If `pod install` or `swift package resolve` ever appears in instructions, it's wrong.

## First-time setup

```bash
cd NeoAstro
xcodegen generate
open NeoAstro.xcodeproj
```

That's it. No `.env`, no API keys to configure – the app talks to a public stage URL by default and stores tokens in Keychain after login.

## Project regeneration

`NeoAstro.xcodeproj/project.pbxproj` is generated from `project.yml` by XcodeGen. **Do not hand-edit `project.pbxproj`.** Anything you change there is wiped on the next regeneration.

If you add a new top-level folder under `NeoAstro/NeoAstro/`, run `xcodegen generate` to pick it up. Adding files inside an existing folder is usually picked up automatically by Xcode's group sync.

## Branching

The repo currently isn't under git (run `git init` if you're starting fresh). When you do put it under version control:

| Type | Branch |
|------|--------|
| Mainline | `main` |
| Feature work | `feature/<short-slug>` |
| Bug fixes | `bugfix/<short-slug>` |
| Release cuts | `release/<version>` |

Match the parent monorepo's convention so the iOS branches parallel `zupee-rn-astro` releases.

## Code style

- **One ViewModel = one class**, marked `@Observable @MainActor final class`. No `ObservableObject`.
- **Async only** for I/O. Don't reach for `Combine` or `DispatchQueue.global`. The single allowed actor is `APIClient`.
- **Early returns** to keep nesting shallow. Prefer `guard let` over deep `if let` ladders.
- **No emoji in source files.** (Emoji in `AppLog` console output is fine – they aid log filtering. Don't add them to UI strings unless explicitly designed.)
- **No comments restating code.** Only comment where the *why* would surprise a future reader (e.g. "header value is intentional, see AGENTS.md note 3").
- **No `print`, no `NSLog`.** Use `AppLog.<category>`.
- **Strict typing.** Avoid `Any`, avoid `AnyCodable`. Prefer enums over stringly-typed values.

## Adding a feature

Follow the recipe in [AGENTS.md – Adding a new feature](AGENTS.md#adding-a-new-feature-recipe):

1. `Features/<Name>/<Name>View.swift` + `<Name>ViewModel.swift`
2. `Models/API/<Name>API.swift` for any new DTOs
3. `Services/<Name>Service.swift` enum facade calling `APIClient.shared.send`
4. Wire navigation via `NavigationStack` + `.navigationDestination(item:)`
5. If it's a new tab, add a case to `AppTab` and a `Tab` entry in `MainTabView`

## Adding an endpoint

1. Add request/response DTOs to `Models/API/`.
2. Add a static method on the relevant `*Service` calling `APIClient.shared.send`.
3. Don't touch `APIClient` itself – it already handles auth, headers, refresh, and the three envelope shapes.
4. If a non-standard header is required, pass it via `Request.extraHeaders`.

## Logging

`AppLog` (in `Networking/AppLog.swift`) is the only logger. Categories today: `api`, `auth`, `home`, `search`, `account`, `wallet`, `horoscope`, `panchang`, `chat`. Add new categories rather than misusing existing ones.

`APIClient` already logs every request and response with timing, status, truncated body, and redacted headers. Don't double-log at the service layer.

## Building from CLI

```bash
xcodebuild -project NeoAstro.xcodeproj \
           -scheme NeoAstro \
           -destination 'generic/platform=iOS Simulator' \
           build
```

For a device build you need the `H5YRX72888` team enrolled and an `Apple Development` certificate in the keychain.

## Things to discuss before merging

- **First third-party dependency.** The "no SDKs" stance is intentional. Adding Firebase / Sentry / Razorpay / CleverTap / Agora needs explicit alignment.
- **Bundle ID change.** Provisioning + App Store Connect + backend allow-lists are tied to `varasol.MarathiCalendarPanchangam`. Don't change unilaterally.
- **`DeviceInfo.zupeeAppName`** changes from `com.neoastro.android` will 403 every request without a coordinated backend update.
- **Lowering the deployment target** below iOS 26 will require auditing `Tab`, `@Observable`, and `searchable` usage. Don't do it as a side effect.
- **Caching layer** (Core Data, SwiftData, NSCache) – the app is intentionally stateless beyond Keychain. Add caching only with a real product requirement.

## Things you don't need to coordinate

- New features under `Features/` that follow the existing pattern.
- New endpoints in existing `*Service` enums.
- UI tweaks in `Components/` and `AppTheme.swift`.
- New `AppLog` categories.
- New DTO fields in `Models/API/` (keep them optional to avoid breaking older builds).

## Test plan reminder (until we have a test target)

For now there's no automated test suite. Until one exists, the bare-minimum manual matrix for any non-trivial change:

- [ ] Cold launch on iPhone simulator – lands on `LoginView` if no token, `MainTabView` if `TokenStore.isAuthenticated`.
- [ ] OTP auth → tokens persisted → kill + relaunch → still authenticated.
- [ ] Each tab loads at least once without a `decoding` or `transport` error in `AppLog`.
- [ ] Force-expire tokens in stage → `APIClient` triggers `/v1.0/refreshToken` and the original request replays.
- [ ] `Account → Logout` clears Keychain and returns to `LoginView`.

Adding XCTest / XCUITest targets is welcome – just add them to `project.yml` and re-run XcodeGen.
