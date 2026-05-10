# NeoAstro iOS – Feature Parity Matrix

This is the porting checklist. Every feature in the React Native user app (`zupee-rn-astro`) is listed here with its current iOS status. **All of them will be ported** — this doc tracks what's done, what's partial, and what's still TODO.

> **Companions:** [API-ENDPOINTS.md](.claude/references/API-ENDPOINTS.md) for HTTP, [SOCKET-EVENTS.md](.claude/references/SOCKET-EVENTS.md) for realtime, [UI-GUIDELINES.md](.claude/references/UI-GUIDELINES.md) for Liquid Glass conventions.

> **UI rule for everything below:** every new screen and component must follow the Liquid Glass guidelines in [UI-GUIDELINES.md](.claude/references/UI-GUIDELINES.md). No flat plastic cards, no opaque navigation chrome.

## Status legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Done – matches RN parity |
| 🟡 | Partial – basic flow works, gaps remain |
| 🟦 | Stub – placeholder exists, needs real implementation |
| ⏳ | TODO – not started |
| ❓ | Verify scope with product before porting |

---

## 1. Authentication & Onboarding

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Splash / cold start | ✅ | [Features/Splash/SplashView.swift](NeoAstro/Features/Splash/SplashView.swift) | `screens/splash/Splash.tsx` | Animated logo, fires `AppConfigStore.bootstrap()`, routes via `AuthViewModel.routeAfterBootstrap` |
| Phone-number login | ✅ | [Features/Auth/LoginView.swift](NeoAstro/Features/Auth/LoginView.swift) | `screens/Login/Login.tsx` | |
| OTP verification | ✅ | [Features/Auth/OTPView.swift](NeoAstro/Features/Auth/OTPView.swift) | `screens/verifyOtp/VerifyOtp.tsx` | Resend countdown + auto-fill done |
| Auth stage state machine | ✅ | [Features/Auth/AuthViewModel.swift](NeoAstro/Features/Auth/AuthViewModel.swift) | `appState` Zustand slice | |
| Token refresh on 401 | ✅ | [Networking/APIClient.swift](NeoAstro/Networking/APIClient.swift) | `src/api/index.ts` | Single in-flight refresh, deduped |
| Truecaller signup | ⏳ | — | `useTrueCallerAuthApi.ts` | Optional; needs SDK |
| Pre-signup config | ✅ | [Services/ConfigService.swift](NeoAstro/Services/ConfigService.swift) | `usePreSignupApi.ts` | Best-effort fetch on splash; falls back to hardcoded language list |
| Post-signup config | ✅ | [Services/ConfigService.swift](NeoAstro/Services/ConfigService.swift) | `services/AuthService.ts` | Fetched after authenticate; drives `needsOnboarding` |
| Language selection | ✅ | [Features/Onboarding/LanguageSelectionView.swift](NeoAstro/Features/Onboarding/LanguageSelectionView.swift) | `screens/SelectLanguage` | First-launch picker; persists to `TokenStore.language`; `DeviceInfo.language` reads from it |
| Onboarding questionnaire (birth details for Kundli) | ✅ | [Features/Onboarding/OnboardingView.swift](NeoAstro/Features/Onboarding/OnboardingView.swift) | `screens/questionnaire` | 4-step wizard (name+gender → DOB → time → place); place autocomplete deferred |
| Mark onboarding complete | ✅ | [Services/OnboardingService.swift](NeoAstro/Services/OnboardingService.swift) | `setOnboardingCompleted` API | Server flag + Keychain hint mirror |
| Referral code entry | ⏳ | — | `screens/AddReferralCode.tsx` | |
| Referral success screen | ⏳ | — | `screens/ReferralCodeSuccess.tsx` | |
| Logout | 🟡 | [Features/Account/AccountViewModel.swift](NeoAstro/Features/Account/AccountViewModel.swift) | `account/index.tsx` | TokenStore.clear works; needs full session teardown |
| Delete account | ✅ | [Features/Account/AccountViewModel.swift](NeoAstro/Features/Account/AccountViewModel.swift) | `deleteUserAccount.ts` | |
| Force-update gating | ⏳ | — | `AppUpdateService` | Must block app if version too old |

---

## 2. Discovery (Astrologer Browsing)

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Astrologer list (widgetised) | ✅ | [Features/Home/HomeView.swift](NeoAstro/Features/Home/HomeView.swift) | `screens/home/index.tsx` | Cards via `AstrologerCard` |
| Hero banner | 🟡 | HomeView | — | Static today; backend banners not fetched |
| Pull-to-refresh | ✅ | HomeView | shared util | |
| Search bar (overlay) | 🟡 | [Features/Search/SearchOverlayView.swift](NeoAstro/Features/Search/SearchOverlayView.swift) | `home/SearchAstrologer.tsx` | Needs categories + trending + recent |
| Recent searches | ⏳ | — | `getRecentSearches`, `addRecentSearch`, `clearRecentSearches` | |
| Trending searches | ⏳ | — | server-driven list | |
| Astrologer profile | 🟡 | [Features/Home/AstrologerProfileView.swift](NeoAstro/Features/Home/AstrologerProfileView.swift) | `screens/astrologerProfile/index.tsx` | Bio + rating only; no stories, no reviews tab |
| Astrologer stories carousel | ⏳ | — | `AllStories.tsx` | |
| Astrologer reviews | ⏳ | — | `/v1.0/astrologer/reviews` | |
| Astrologer popup details | ⏳ | — | `getPopupDetails` | |
| Astrologer metadata | ⏳ | — | `getAstrologerMetadata` | |
| "Notify me when online" | ⏳ | — | `chat/notifyUser` | |
| Best astrologers modal | ⏳ | — | `bestAstrologers/index.tsx` | |
| Live players info | ⏳ | — | `getLivePlayersInfo` | |
| Real-time online indicator | ⏳ | — | `ASTROLOGER_STATUS_UPDATE` socket | Needs realtime layer |
| Wait-time chip per astrologer | ⏳ | — | `ASTROLOGER_WAITTIME_UPDATE` | |

---

## 3. Chat (Per-Minute)

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Chat confirmation sheet | ✅ | [Features/Home/ChatConfirmationSheet.swift](NeoAstro/Features/Home/ChatConfirmationSheet.swift) | `home/index.tsx` | Pricing breakdown, info chips, system Liquid Glass sheet |
| Birth-details prompt before chat | ⏳ | — | `chat/getSampleBirthLocation` | Lands when birth-details revalidation is wired |
| Initiate chat (CTA) | ✅ | [Features/Home/HomeView.swift](NeoAstro/Features/Home/HomeView.swift) | `INITIATE_CHAT` socket | `startChat(with:)` emits `INITIATE_CHAT` and pushes `ChatView` |
| Chat screen | ✅ | [Features/Chat/ChatView.swift](NeoAstro/Features/Chat/ChatView.swift) | `cx/chat/ChatScreen.tsx` | Real chat screen (replaces stub); waits for `CHAT_STARTED`; live billing pill |
| Send text message | ✅ | [Features/Chat/ChatViewModel.swift](NeoAstro/Features/Chat/ChatViewModel.swift) | `RAISE_QUERY` w/ ack-retry | Optimistic insert + 3-retry exponential ack via `NeoAstroSocket.emitWithAck` |
| Send voice note | ✅ | [Realtime/Audio/AudioRecorder.swift](NeoAstro/Realtime/Audio/AudioRecorder.swift) | `getVoiceNotePreSignedUrl` + `RAISE_QUERY` | Press-and-hold mic in `ChatInputBar`, slide-to-cancel, live waveform overlay, `AVAudioRecorder` (m4a / AAC), 60 s cap, 2-step presigned upload via `ChatMediaService.uploadVoiceNote`, optimistic insert with local file URL → patched to public URL after upload |
| Send image | ✅ | [Features/Chat/ChatInputBar.swift](NeoAstro/Features/Chat/ChatInputBar.swift) | `getImagePreSignedUrl` + `RAISE_QUERY` | `PhotosPicker` in input bar, presigned upload via `ChatMediaService.uploadImage`, image bubble with rounded glass + tap-to-lightbox |
| Audio playback (mini player) | ✅ | [Realtime/Audio/AudioPlayer.swift](NeoAstro/Realtime/Audio/AudioPlayer.swift) | `AudioPlayerModule` bridge | Single-instance `AudioPlayer.shared` (`@Observable` singleton) — only one bubble plays at a time; tap-to-toggle on audio bubbles drives a progress bar |
| Reply / quote message | ⏳ | — | `replyTo` / `repliedAgainst` fields | |
| Receive message | ✅ | [Features/Chat/ChatViewModel.swift](NeoAstro/Features/Chat/ChatViewModel.swift) | `ANSWER_QUERY` socket | Drained from `RealtimeStore.inboundMessages` with id-dedup |
| Typing indicators (both sides) | ✅ | [Features/Chat/ChatView.swift](NeoAstro/Features/Chat/ChatView.swift) | `USER_TYPING` / `ASTRO_TYPING(_STOP)` | User typing debounced 1.5 s; astro indicator driven by `astroTypingUntil` |
| Read receipts | ⏳ | — | `HUMAN_ANSWER_SEEN` | Emit only on actual scroll — Batch 4b |
| Recording indicators (astrologer) | ⏳ | — | `ASTRO_RECORDING_*` | Events handled by store; UI fold-in next |
| Low-balance system message | ✅ | [Realtime/handlers/ChatEventHandler.swift](NeoAstro/Realtime/handlers/ChatEventHandler.swift) | `LOW_BALANCE_NOTIF` | Synthesises a SYSTEM_LOW_BALANCE bubble into the chat |
| Payment update banner | 🟡 | [Realtime/SocketEvent.swift](NeoAstro/Realtime/SocketEvent.swift) | `UPDATE_PAYMENT` | Event known; UI banner deferred |
| Recharge CTA from chat | ⏳ | — | `IN_CHAT_RECHARGE_CTA_CLICKED` | Wires once recharge sheet lands in chat |
| End chat | ✅ | [Features/Chat/ChatView.swift](NeoAstro/Features/Chat/ChatView.swift) | `END_CHAT` / `CHAT_ENDED` | Toolbar phone-down → confirmation dialog → emit |
| Chat history list | ⏳ | — | `screens/conversations/index.tsx` | |
| Per-astrologer chat history | ⏳ | — | `chat/getHistoryWithAstrologer` | |
| Live chat details fetch | ⏳ | — | `chat/getLiveChatDetails` | |
| Delete chat with one astrologer | ⏳ | — | `chat/deleteChatHistory` | |
| Delete all chat history | ⏳ | — | `chat/deleteAllChatHistory` | |
| Waitlist screen | 🟡 | [Features/Chat/ChatView.swift](NeoAstro/Features/Chat/ChatView.swift) | `WAITLIST_JOINED` + `screens/waitingScreen` | Inline waiting state inside ChatView (display text from `WAITLIST_JOINED`); standalone waitlist screen TBD |
| Incoming chat (astrologer-initiated) | 🟡 | [Realtime/handlers/ChatEventHandler.swift](NeoAstro/Realtime/handlers/ChatEventHandler.swift) | `INCOMING_CHAT` | Event handled (logged); UI surface deferred |
| Chat initiation failed modal | ✅ | [Features/Chat/ChatView.swift](NeoAstro/Features/Chat/ChatView.swift) | `CHAT_INITIATION_FAILED` | Inline error card with heading/sub/close inside the waiting state |

---

## 4. Voice Call (Per-Minute)

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Outgoing call initiation | ⏳ | — | `/v1.0/call/initiateCall` | Lands with Batch 4b (Agora) |
| Incoming call full-screen UI | 🟡 | [Features/Calls/IncomingCallView.swift](NeoAstro/Features/Calls/IncomingCallView.swift) | `IncomingCallModule` | Liquid Glass UI shell with pulse rings + accept/reject; Agora hookup is Batch 4b. Custom UI (not CallKit) to match RN behavior |
| Accept call | 🟡 | [Navigation/RootView.swift](NeoAstro/Navigation/RootView.swift) | `CALL_ACCEPTED` + `InitiateChatModule.initiateChat` | Signaling side wired (clears `incomingCall`); Agora join + chat linkage is Batch 4b |
| Reject call | ✅ | [Realtime/handlers/CallEventHandler.swift](NeoAstro/Realtime/handlers/CallEventHandler.swift) | `CALL_REJECTED` | `incomingCall` cleared on reject/cancel/end |
| Cancel outgoing call | ⏳ | — | `cancelCall` API | Lands with outgoing-call flow (Batch 4b) |
| Agora audio engine | ⏳ | — | Agora RTC SDK | **Decision pending** — Batch 4b blocker |
| Call status update | 🟡 | [Realtime/handlers/CallEventHandler.swift](NeoAstro/Realtime/handlers/CallEventHandler.swift) | `INCHAT_CALL_STATUS_UPDATE` | Event known; chat-message linkage deferred |
| Call ended | ✅ | [Realtime/handlers/CallEventHandler.swift](NeoAstro/Realtime/handlers/CallEventHandler.swift) | `CALL_ENDED` | Clears incoming-call surface |
| Call initiation failed | ✅ | [Realtime/handlers/CallEventHandler.swift](NeoAstro/Realtime/handlers/CallEventHandler.swift) | `CALL_INITIATION_FAILED` w/ recommendations | Clears state; recommendations UI lands with outgoing-call flow |
| Last call session | ⏳ | — | `getLastCallSession` | |
| Return-to-call bar | ⏳ | — | persistent footer when in call | Lands with Agora |
| Ringtone playback | ⏳ | — | `RingtoneModule` bridge | iOS uses `AVAudioPlayer` — Batch 4b |
| Call duration display + balance ticker | ⏳ | — | `timeLeftToChat` | Lands with Agora |

---

## 5. Video / Fixed-Price Consultation ("Quick Consult")

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Consult tab in dashboard | ⏳ | — | `consult/ConsultScreen.tsx` | Behind feature flag in RN |
| Astrologer consultation profile | ⏳ | — | `astrologerConsultationProfile/index.tsx` | Pricing + slot duration |
| Consult value-prop screen | ⏳ | — | `consultValueProp` | |
| Consult matchmaking | ⏳ | — | `consultMatchmaking` | |
| Communication mode sheet (chat / call / video) | ⏳ | — | `mode-switch` API | |
| Birth-details verification gate | ⏳ | — | re-check before consult | |
| Consultation packages list | ⏳ | — | `/v1.0/video-consultation/packages` | |
| Initiate video consultation | ⏳ | — | `/v1.0/video-consultation/initiate` | |
| Active consultation session | ⏳ | — | `/v1.0/video-consultation/active` | |
| Consult chat screen | ⏳ | — | `consultChat/ConsultChatScreen.tsx` | |
| Consultation accepted | ⏳ | — | `VIDEO_CONSULT_ACCEPTED` + `ConsultCallModule.consultationAccepted` | |
| Consultation rejected | ⏳ | — | `VIDEO_CONSULT_REJECTED` | |
| Consultation timed out | ⏳ | — | `VIDEO_CONSULT_TIMED_OUT` | |
| End consultation | ⏳ | — | `/v1.0/video-consultation/end` + `VIDEO_CONSULT_ENDED` | |
| Mode switch (chat ↔ call ↔ video) | ⏳ | — | `CONSULTATION_MODE_SWITCH_*` | |
| Cancel mode switch | ⏳ | — | `switch-mode/cancel` | |
| Rate consultation | ⏳ | — | `/v1.0/video-consultation/rate` | |
| Consultation report (AI) | ⏳ | — | `CONSULTATION_REPORT_READY` | Inject as system message |
| Consult Free Chat (within consult) | ⏳ | — | `INITIATE_CONSULT_FREE_CHAT` | |
| Consult guidance screen | ⏳ | — | `consultFreeChat/ConsultGuidanceScreen.tsx` | |
| Picture-in-Picture for video call | ⏳ | — | iOS `AVPictureInPictureController` | |
| Native Consult call activity | ⏳ | — | `ConsultCallModule` / `ConsultCallViewController` | |
| Consultation summary | ⏳ | — | `consultation/ConsultationSummaryScreen.tsx` | |

---

## 6. Free Ask (one-shot Q&A)

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Free Ask entry | ✅ | [Features/Home/HomeView.swift](NeoAstro/Features/Home/HomeView.swift) | `freeAsk/FreeAskTabWrapper.tsx` | Glass tile on Home opens the flow as a sheet |
| Select free question | ✅ | [Features/FreeAsk/SelectFreeQuestionView.swift](NeoAstro/Features/FreeAsk/SelectFreeQuestionView.swift) | `selectFreeQuestion` | 10-tile category grid with hardcoded fallback list |
| Submit free question | ✅ | [Features/FreeAsk/FreeAskComposeView.swift](NeoAstro/Features/FreeAsk/FreeAskComposeView.swift) | `chat/freeAsk` + `FREE_ASK` socket | Validates 10–240 chars; emits socket + REST fallback |
| Live astrologer slider | 🟡 | [Features/FreeAsk/FreeAskWaitingView.swift](NeoAstro/Features/FreeAsk/FreeAskWaitingView.swift) | `freeAskSlider` | Slider replaced with progress hero + bar; full slider UI deferred |
| Wait/progress bar UI | ✅ | [Features/FreeAsk/FreeAskWaitingView.swift](NeoAstro/Features/FreeAsk/FreeAskWaitingView.swift) | `FREE_ASK_SUBMITTED` | Pulsing rings + animated progress bar driven by `progressBarTime` |
| View answers (multi-astrologer) | ✅ | [Features/FreeAsk/FreeAskAnswersView.swift](NeoAstro/Features/FreeAsk/FreeAskAnswersView.swift) | `freeAskAnswers/index.tsx` | Question card + answer card + recommended chips + next-ask cooldown |
| Mark answer as read | ✅ | [Features/FreeAsk/FreeAskAnswersView.swift](NeoAstro/Features/FreeAsk/FreeAskAnswersView.swift) | `ANSWER_VIEWD` (typo intentional) | Auto-emits on screen appear with the astroId |
| Recommended astrologers in answer | ✅ | [Features/FreeAsk/FreeAskAnswersView.swift](NeoAstro/Features/FreeAsk/FreeAskAnswersView.swift) | `FREE_ASK_ANSWERED.recommendedAstrologers` | Horizontal scroll of glass chips → tap routes to chat-confirmation sheet |
| Free Ask small/large nudge | ⏳ | — | `FREE_ASK_*_NUDGE_CLICKED` | Banner placement TBD |
| Astro price update (offer) | ✅ | [Realtime/handlers/FreeAskEventHandler.swift](NeoAstro/Realtime/handlers/FreeAskEventHandler.swift) | `ASTRO_FREE_ASK_PRICE_UPDATE` | Stored on `RealtimeStore.freeAskOfferPrices` map |
| Daily-limit gate | ⏳ | — | server-enforced | Backend returns business failure on retry |

> Reminder: Free Ask ≠ Free Chat. Don't conflate. Consultation-enabled astrologers ARE eligible for Free Ask.

---

## 7. Free Chat (first-chat-free)

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Match for Free Chat | ✅ | [Services/FreeAskService.swift](NeoAstro/Services/FreeAskService.swift) | `chat/consult-free-chat/match` | `FreeAskService.matchFreeChat()` |
| Initiate Free Chat | ✅ | [Features/FreeChat/FreeChatWaitingView.swift](NeoAstro/Features/FreeChat/FreeChatWaitingView.swift) | `INITIATE_FREE_CHAT` | Emitted on assignment, before CHAT_STARTED |
| Free Chat waitlist | ✅ | [Features/FreeChat/FreeChatWaitingView.swift](NeoAstro/Features/FreeChat/FreeChatWaitingView.swift) | `FREE_CHAT_WAITLIST` | Display text rendered live on the waiting view |
| Astrologer assigned event | ✅ | [Realtime/handlers/FreeAskEventHandler.swift](NeoAstro/Realtime/handlers/FreeAskEventHandler.swift) | `FREE_CHAT_ASTRO_ID` | Sets `RealtimeStore.freeChatAssignedAstroId`; HomeView routes into ChatView |

---

## 8. Horoscope

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Daily / weekly / monthly tabs | ✅ | [Features/Horoscope/HoroscopeView.swift](NeoAstro/Features/Horoscope/HoroscopeView.swift) | `horroscope/index.tsx` | |
| Sign selector | 🟡 | HoroscopeView | — | iOS uses zodiac stored in TokenStore; no manual override yet |
| Pending-state retries | ✅ | [Features/Horoscope/HoroscopeViewModel.swift](NeoAstro/Features/Horoscope/HoroscopeViewModel.swift) | shared service | 7×, 5 s backoff |
| Horoscope from specific astrologer | ⏳ | — | `getHoroscopeAstrologer` | |
| Lucky-entity widgets | ✅ | HoroscopeView | — | |
| Recommended astrologer in horoscope | 🟡 | HoroscopeView | — | Row exists; tap action TBD |

---

## 9. Panchang

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Today's panchang | ✅ | [Features/Panchang/PanchangView.swift](NeoAstro/Features/Panchang/PanchangView.swift) | `screens/panchang` | |
| Hero / sun-moon / kaal / chaughadiya / nakshatra widgets | ✅ | PanchangView | — | Tagged-union decode in `PanchangAPI` |
| Date picker (other days) | ⏳ | — | RN appears to support only today | Verify scope |
| Calendar export | ⏳ | — | RN doesn't have it | ❓ |

---

## 10. Wallet & Balance

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Wallet screen data | ✅ | [Features/Wallet/WalletView.swift](NeoAstro/Features/Wallet/WalletView.swift) | `wallet/index.tsx` | Quick-link tiles for Cashback / TDS added |
| Balance check | 🟡 | WalletView | `useCheckWalletBalance` | Pulled via screen-data only; no direct refresh API yet |
| Transaction passbook | ✅ | [Features/Wallet/WalletViewModel.swift](NeoAstro/Features/Wallet/WalletViewModel.swift) | `txnHistory/TransactionHistory.tsx` | Rows now navigate to `TransactionDetailView` |
| Transaction filters | ✅ | [Features/Wallet/TransactionFilterSheet.swift](NeoAstro/Features/Wallet/TransactionFilterSheet.swift) | `transactionHistory/filters` | Glass chip flow-layout sheet driven by server filters with offline fallback; passbook re-queries on apply |
| Transaction detail view | ✅ | [Features/Wallet/TransactionDetailView.swift](NeoAstro/Features/Wallet/TransactionDetailView.swift) | `txnDetails/TransactionInfo.tsx` | Glass amount hero + details list + invoice card |
| Cashback / coins listing | ✅ | [Features/Wallet/CashbackView.swift](NeoAstro/Features/Wallet/CashbackView.swift) | `fetchActiveCashbackCoins`, `cashback/Cashback.tsx` | Active-coins hero + offer rows + convert CTA |
| Convert actual → playable coins | ✅ | [Features/Wallet/CashbackView.swift](NeoAstro/Features/Wallet/CashbackView.swift) | `payment/convertActualCoins` | Wired into Cashback "Convert to wallet" button |
| Invoices | ✅ | [Features/Wallet/InvoicesView.swift](NeoAstro/Features/Wallet/InvoicesView.swift) | `wallet/getInvoices` | List view reachable from WalletView quick-links row; download chevron when URL present |
| TDS certificates | ✅ | [Features/Wallet/TDSView.swift](NeoAstro/Features/Wallet/TDSView.swift) | `wallet/tds/*`, `tds/getUserTdsInfo` | Summary card + certificate list (download URL ready) |
| TDS / GST txn history | 🟡 | [Services/WalletService.swift](NeoAstro/Services/WalletService.swift) | `cx/tdsAndGstTxnScreen` | `tdsTransactionsOfQuarter` service ready; UI fold-in next |
| Low-balance nudge in chat | ⏳ | — | `LOW_BALANCE_NOTIF` | (also under Chat) |

---

## 11. Payment / Deposit / Checkout

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Deposit screen (general) | ⏳ | — | `deposit/index.tsx`, `getDepositScreenData` | |
| Deposit per-astrologer | ⏳ | — | `getDepositScreenDataBasedOnAstrologer` | |
| Initiate checkout | ⏳ | — | `payment/initiateCheckout` | |
| Create checkout order | 🟡 | [Features/Wallet/WalletViewModel.swift](NeoAstro/Features/Wallet/WalletViewModel.swift) | `checkoutOrder/create` | API call exists |
| Juspay HyperSDK presentation | 🟦 | [Features/Wallet/JuspayPaymentSheet.swift](NeoAstro/Features/Wallet/JuspayPaymentSheet.swift) | `screens/deposit/checkout.tsx` | Stub; SDK not integrated |
| Quick checkout (saved instrument) | ⏳ | — | `payment/quickCheckout` | |
| Payment configuration | ⏳ | — | `payment/getPaymentConfig` | |
| Checkout meta config | ⏳ | — | `getCheckoutMetaConfigs` | |
| Apply / validate coupon | ⏳ | — | `reward/validateCoupon` | |
| Best coupon suggestion | ⏳ | — | `reward/getBestCoupon` | |
| Fraud-detection check | ⏳ | — | `payment/checkFraudDetection` | |
| Payment status screen | ⏳ | — | `deposit/PaymentStatus/index.tsx` | |
| UPI deep payment flow | ⏳ | — | `deposit/PaymentViaUpi` | |
| Verify VPA | ⏳ | — | `payment/verifyVpa` | |
| Order status (deposit) | ⏳ | — | `payment/v2/order/status/deposit` | |

---

## 12. Withdrawal

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| FTW (first-time withdrawal) screen | ⏳ | — | `payment/fetchFtwScreenData` | |
| Initialize withdrawal session | ⏳ | — | `payment/initializeWithdrawalSession` | |
| Withdrawal debounce widget | ⏳ | — | `withdrawalDebounceWidgetData` | |
| Process withdrawal | ⏳ | — | `payment/processWithdrawal` | |
| Saved withdrawal modes | ⏳ | — | `getSavedWithdrawalModes` | |
| Add UPI ID | ⏳ | — | `addUpiId` | |
| Add bank account | ⏳ | — | `payment/bank/submit` | |
| Payout to bank | ⏳ | — | `payment/payoutToUserBank` | |
| Withdrawal status / tracking | ⏳ | — | `withdraw/WithdrawStatus.tsx` | |
| KYC gate before withdrawal | ⏳ | — | bottomsheet | |
| TDS pre-display | ⏳ | — | server payload | |
| Cool-off enforcement | ⏳ | — | server payload | |
| CX withdraw-and-deposit dispute | ⏳ | — | `cx/withdrawAndDeposit` | |

---

## 13. Rewards / Coupons / Cashback

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Cashback screen | ⏳ | — | `cashback/Cashback.tsx` | |
| Validate coupon | ⏳ | — | `reward/validateCoupon` | |
| Best coupon | ⏳ | — | `reward/getBestCoupon` | |
| Save scratch card | ⏳ | — | `reward/saveScratchCardData` | |
| Scratch card UI | ⏳ | — | (RN component) | |

---

## 14. KYC / Compliance

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| KYC docs requirement | ⏳ | — | `getKycDocsV3` | |
| KYC consent | ⏳ | — | `acceptKycConsent` | |
| Generate KYC OTP | ⏳ | — | `generateKycOtp` | |
| Submit KYC OTP | ⏳ | — | `submitKycOtp` | |
| Submit KYC async (Aadhaar / PAN) | ⏳ | — | `submitKycAsyncV2` | |
| Verify Aadhaar (paperless OTP) | ⏳ | — | `verifyAadhar` | |
| PAN paperless / OTP-less | ⏳ | — | `kyc/panPaperless` | |
| Auto-verify approve / decline | ⏳ | — | `approveAutoVerifyKyc` / `declineAutoVerifyKyc` | |
| KYC status bottomsheet | ⏳ | — | `KycStatusBottomsheet.tsx` | |
| KYC restriction nudges | ⏳ | — | wallet / withdrawal entry points | |

---

## 15. Helpdesk / Support

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Helpdesk home (widgetised) | ⏳ | — | `helpdeskWidget/getHelpdeskWidgetisedHomePage` | |
| Topics + tickets list | ⏳ | — | `getHelpdeskTopicsAndTickets` | |
| Subtopics navigation | ⏳ | — | `cx/subtopics/SubTopics.tsx` | |
| Create ticket | ⏳ | — | `createNewHelpdeskTicket` + `cx/createTicket` | |
| Ticket detail | ⏳ | — | `getHelpdeskTicket` | |
| Add comment | ⏳ | — | `addHelpdeskTicketComment` | |
| Upload attachment | ⏳ | — | `uploadHelpdeskAttachment` + `getFileUploadPreSignedURL` | |
| Spam check | ⏳ | — | `checkTicketCreationSpam` | |
| Past tickets list | ⏳ | — | `screens/pastTickets`, `screens/ticketHistory` | |
| Ticket creation status | ⏳ | — | `cx/createTicket/CreateTicketStatus.tsx` | |
| CSAT feedback | ⏳ | — | `helpdesk/submitCsat` | |
| Transaction help topics | ⏳ | — | `getHelpdeskTransactionTopics` | |
| Helpdesk by transaction id | ⏳ | — | `getHelpdeskDetailsByTid` | |
| Live chat with support | ⏳ | — | `screens/chatSupport` | |
| Image / video preview | ⏳ | — | `cx/preview/ImageAndVideoPreview.tsx` | |

---

## 16. Profile

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| View profile | ✅ | [Features/Account/AccountView.swift](NeoAstro/Features/Account/AccountView.swift) | `screens/profile` | |
| Edit profile | ✅ | [Features/Account/EditProfileView.swift](NeoAstro/Features/Account/EditProfileView.swift) | `editProfile/EditProfile.tsx` | name, email, gender, city, state |
| Upload profile picture | ✅ | [Features/Account/EditProfileView.swift](NeoAstro/Features/Account/EditProfileView.swift) | `uploadProfilePic` | `PhotosPicker` overlaid on the avatar; 2-step presigned upload via `ProfileService.uploadProfilePic`; `EditProfilePayload.profilePictureUrl` patched on save |
| Submit astrology questionnaire | ✅ | [Services/OnboardingService.swift](NeoAstro/Services/OnboardingService.swift) | `submitAstroUserDetails` | Wired into Onboarding flow (Batch 2) |
| Send appography details | ⏳ | — | `sendAppographyDetails` | Skipped — overlaps with `submitAstroUserDetails`; revisit if backend distinguishes them |
| Set user location | ✅ | [Services/ProfileService.swift](NeoAstro/Services/ProfileService.swift) | `setUserLocation` | Service ready; UI fold-in lands with place autocomplete |
| Update GA / advertising id | ✅ | [Services/ProfileService.swift](NeoAstro/Services/ProfileService.swift) | `updateGAId` | Service ready; called from analytics layer when added |
| Get rejoin info | ✅ | [Services/ProfileService.swift](NeoAstro/Services/ProfileService.swift) | `getRejoinInfo` | Service ready; UI surface as needed |
| User experience setting | ✅ | [Services/ProfileService.swift](NeoAstro/Services/ProfileService.swift) | `userExperience/updateUserExperience` | Service ready |

---

## 17. Settings & More

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Settings widgets (server-driven) | ✅ | [Features/More/MoreView.swift](NeoAstro/Features/More/MoreView.swift) | `getUserSettings` | |
| Account access | ✅ | MoreView | — | |
| Logout flow | ✅ | MoreView | — | |
| Delete-account confirmation | ✅ | MoreView | — | |
| About / Privacy / Terms (in-app browser) | 🟡 | MoreView | `ZupeeWebview` | Opens in `SFSafariViewController`; verify URLs |
| Notification preferences | ⏳ | — | server payload | |
| Language preference | ⏳ | — | tied to onboarding | |

---

## 18. Notifications

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Push notification registration (APNs) | ✅ | [App/AppDelegate.swift](NeoAstro/App/AppDelegate.swift) | iOS uses APNs; backend endpoint is `fcmToken` | `UIApplicationDelegateAdaptor` wired in `NeoAstroApp`; auth requested at launch; **needs Push Notifications capability added in Xcode target settings** |
| Update push token | ✅ | [Services/NotificationService.swift](NeoAstro/Services/NotificationService.swift) | `misc/fcmToken` | Auto-uploaded on `didRegisterForRemoteNotificationsWithDeviceToken` |
| Notification center / history | ✅ | [Features/Notifications/NotificationCenterView.swift](NeoAstro/Features/Notifications/NotificationCenterView.swift) | `screens/notification/Notification.tsx` | Reachable via bell icon in HomeView toolbar |
| Read notification | ✅ | [Features/Notifications/NotificationCenterView.swift](NeoAstro/Features/Notifications/NotificationCenterView.swift) | `misc/readNotification` | Tap row → marks read |
| Clear single notification | ✅ | [Features/Notifications/NotificationCenterView.swift](NeoAstro/Features/Notifications/NotificationCenterView.swift) | `misc/clearNotification` | Swipe-to-clear |
| Clear all notifications | ✅ | [Features/Notifications/NotificationCenterView.swift](NeoAstro/Features/Notifications/NotificationCenterView.swift) | `misc/clearAllNotifications` | Trash button + confirmation dialog |
| Notification requests detail | ✅ | [Services/NotificationService.swift](NeoAstro/Services/NotificationService.swift) | `getNotificationRequestsDetail` | Backs `NotificationCenterView` list |
| In-app nudges (per screen) | ✅ | [Services/NotificationService.swift](NeoAstro/Services/NotificationService.swift) | `getNudgesByScreenName` | Service ready; per-screen wiring lands as we add nudges |
| Mark nudge shown | ✅ | [Features/Notifications/NudgeBanner.swift](NeoAstro/Features/Notifications/NudgeBanner.swift) | `setUserNudgeShown` | Auto-marked on action / dismiss |
| Astrologer-online system notification | 🟡 | [Realtime/handlers/PresenceEventHandler.swift](NeoAstro/Realtime/handlers/PresenceEventHandler.swift) | `ASTROLOGER_ONLINE_NOTIFICATION` | Stored on `RealtimeStore.astrologerOnlineBanner`; UI banner lands when presented in HomeView |
| Unread badge count | ✅ | [Realtime/handlers/NotificationEventHandler.swift](NeoAstro/Realtime/handlers/NotificationEventHandler.swift) | `UNREAD_MESSAGES_COUNT` + `NRC` | Live in `RealtimeStore.unreadCount` |
| Dynamic nudge banner | ✅ | [Features/Notifications/NudgeBanner.swift](NeoAstro/Features/Notifications/NudgeBanner.swift) | `DYNAMIC_NUDGE` | Reusable component; realtime fan-in lands with Batch 4 |
| Deep-link from notification | ✅ | [App/AppDelegate.swift](NeoAstro/App/AppDelegate.swift) | RN universal links | Tap → extracts `deepLink` / `link` → calls `DeepLinkRouter.handle(deepLink:)` → views consume |

---

## 19. Realtime / Socket Layer

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Socket.IO Swift client integration | ✅ | [Realtime/SocketManager.swift](NeoAstro/Realtime/SocketManager.swift) | `src/socket/AppManager.ts` | First third-party dep (`socket.io-client-swift` 16.1+) wired via XcodeGen |
| Connection authenticated handling | ✅ | [Realtime/handlers/ConnectionEventHandler.swift](NeoAstro/Realtime/handlers/ConnectionEventHandler.swift) | `CONNECTION_AUTHENTICATED` | Sets `RealtimeStore.isConnected`; force-logout on errorCode 256/257 |
| Force-logout via socket | ✅ | [Realtime/handlers/ConnectionEventHandler.swift](NeoAstro/Realtime/handlers/ConnectionEventHandler.swift) | `CONNECTION_MANAGE` | Stops realtime, calls `AuthService.logout()` |
| Notification refresh count | ✅ | [Realtime/handlers/ConnectionEventHandler.swift](NeoAstro/Realtime/handlers/ConnectionEventHandler.swift) | `NRC` | Updates `RealtimeStore.unreadCount` |
| User-details sync on reconnect | 🟡 | [Realtime/SocketEvent.swift](NeoAstro/Realtime/SocketEvent.swift) | `GET_USER_DETAILS` | Event handled; user-details merge into config store deferred |
| Manual reconnection (linear / exponential) | ✅ | [Realtime/ReconnectionPolicy.swift](NeoAstro/Realtime/ReconnectionPolicy.swift) | `ReconnectionHelper` | Socket.IO's built-in retry disabled; linear 100 ms × 120 attempts |
| Event validation guards | ✅ | [Realtime/EventValidation.swift](NeoAstro/Realtime/EventValidation.swift) | `EVENTS_REQUIRING_*` / `SKIP_IF_*` | Ported verbatim |
| Ack-and-retry on `RAISE_QUERY` | ✅ | [Realtime/SocketManager.swift](NeoAstro/Realtime/SocketManager.swift) | exponential backoff | `emitWithAck`: 3 retries × 2 s base, exponential |
| `{ en, data }` envelope codec | ✅ | [Realtime/SocketEnvelope.swift](NeoAstro/Realtime/SocketEnvelope.swift) | `socket.emit("req", ...)` | `req` / `res` channels with typed Encodable / Decodable |
| Token-in-handshake auth | ✅ | [Realtime/SocketManager.swift](NeoAstro/Realtime/SocketManager.swift) | query string params | All zupee-expected params populated; `com.neoastro.android` package name preserved |
| Native bridge: `IncomingCallModule` | 🟡 | [Features/Calls/IncomingCallView.swift](NeoAstro/Features/Calls/IncomingCallView.swift) | exists in RN | UI shell ready; native call ViewController equivalent lands with Agora (Batch 4b) |
| Native bridge: `ConsultCallModule` | ⏳ | — | exists in RN | Batch 4b (consultation flow) |
| Native bridge: `InitiateChatModule` | ⏳ | — | exists in RN | Batch 4b (per-minute voice) |

---

## 20. Native Modules (iOS targets)

| Module | iOS | RN counterpart | Notes |
|--------|:---:|----------------|-------|
| Incoming call full-screen UI | ⏳ | `IncomingCallModule` / `IncomingCallNotificationModule` | Use CallKit `CXProvider` + custom UI |
| Consult call activity (video) | ⏳ | `ConsultCallModule` | Embedded view + PiP |
| Initiate-chat persistence | ⏳ | `InitiateChatModule` | Linkage when call accepted |
| Voice recorder | ⏳ | `VoiceRecorderModule` | `AVAudioRecorder` |
| Audio player (mini) | ⏳ | `AudioPlayerModule` | `AVAudioPlayer` + Now Playing info |
| Ringtone | ⏳ | `RingtoneModule` | `AVAudioPlayer` |
| Truecaller bridge | ⏳ | `TruecallerModule` | Optional |
| Secure flag (screenshot block) | ⏳ | `SecureFlagModule` | Use overlay view on `applicationWillResignActive` |
| Astrologer-online notification | ⏳ | `AstrologerOnlineNotificationManager` | UNNotificationCenter |
| Auth-token storage | ✅ | `AuthTokenModule` | Already done as `TokenStore` (Keychain) |
| Cancel-call | ⏳ | `CancelCallModule` | |
| App-installed checker (intents) | ⏳ | `AppInstalledCheckerModule` | iOS uses `canOpenURL`; LSApplicationQueriesSchemes |
| APK installer | 🚫 | `APKInstallerModule` | Android-only; iOS goes through App Store |

---

## 21. Cross-cutting capabilities

| Capability | iOS | RN reference | Notes |
|------------|:---:|--------------|-------|
| Pull-to-refresh on lists | 🟡 | most lists | Done on Home; needs others |
| In-app update gating | ⏳ | `AppUpdateService` + update banner | iOS uses App Store version check |
| Maintenance mode banner | ⏳ | `Splash.tsx` check | |
| Feature flags | ⏳ | `devSettingsStore` + `switchState` | Today the iOS app has none |
| Analytics events | ⏳ | CleverTap + Firebase | Needs SDK + privacy approval |
| Crash reporting | ⏳ | Sentry | Same |
| Deep linking | ⏳ | `LinkingConfig.ts` | Schemes: `neoastro://wallet`, `…/chat/{astroId}`, `…/consult-chat/{astroId}/{sessionId}`, `…/astrologer-profile/{astroId}`, `…/deposit/{amount}`, `…/ask-free-question` |
| Universal links (`https://www.neoastro.com/…`) | ⏳ | same | Requires apple-app-site-association |
| Pre-auth deep-link queue | ⏳ | RN saves intent before login | |
| Persistent return-to-call bar | ⏳ | shared component | |
| Top banner stack (maintenance / update / astrologer-online) | ⏳ | `TopBannerContainer` | |
| Bottom-sheet system | ⏳ | shared modals | Use SwiftUI `.sheet` / `.presentationDetents` |
| Error boundary | ⏳ | `ChatModalsErrorBoundary` | SwiftUI doesn't have an exact analog; use `Result`-driven views |
| Network logger / dev settings | ⏳ | `screens/devSettings`, `network logger` | iOS has `AppLog` already |
| Performance monitor | ⏳ | `PerformanceMonitor` | |
| Geo-restriction nudge | ⏳ | `LocationRestrictedNudge` | |
| Light & dark mode | ✅ | RN is mostly light-only | iOS supports both per `AGENTS.md` update |
| Localization / i18n | ⏳ | RN uses translations object | App is English-only today |
| Keyboard handling | 🟡 | RN keyboard controller | iOS has `KeyboardDismiss` modifier |

---

## 22. Tournaments / Gaming surface

| Feature | iOS | RN reference | Notes |
|---------|:---:|--------------|-------|
| List tournaments | ❓ | `super/tournament/listTournaments` | Verify scope — gaming side |
| Tournament recommendations | ❓ | `getRecommendation` | |
| Tournament filters | ❓ | `getFiltersV3` | |
| Registered tournaments (helpdesk) | ❓ | `helpdesk/getRegisteredTournaments` | |
| Campaign segment check | ❓ | `super/config/checkCampaignSegmentRTFS` | |

> The astrology user app surfaces some Zupee gaming-platform features. Confirm with product whether NeoAstro iOS should carry them. Marked ❓ until decided.

---

## 23. Developer-only screens

| Feature | iOS | RN reference | Notes |
|---------|:---:|--------------|-------|
| Dev settings panel | ⏳ | `screens/devSettings` | Useful behind a debug build flag |
| SVG / asset gallery | 🚫 | `screens/svgGallery` | Skip — iOS uses `Asset Catalog` |
| Network inspector | 🟡 | RN env-gated | `AppLog` already prints request/response |

---

## Recent batches

- **Batch 5 — Deep-link routing + Batch 3 close-out.** New [DeepLinkRouter](NeoAstro/App/DeepLinkRouter.swift) (`@Observable @MainActor`) parses `neoastro://…` URLs into a typed `Intent` enum (wallet, freeAsk, astrologerProfile, chatWith, deposit, notifications). [Info.plist](NeoAstro/Resources/Info.plist) registers the custom scheme. [NeoAstroApp](NeoAstro/App/NeoAstroApp.swift) injects the router and wires `.onOpenURL { router.handle(url:) }`. [AppDelegate](NeoAstro/App/AppDelegate.swift) gained a `static var deepLinks` bridge so the UIKit notification-tap callback can hand `deepLink` / `link` payload keys to the SwiftUI router; [RootView](NeoAstro/Navigation/RootView.swift) sets the bridge on appear. [MainTabView](NeoAstro/Navigation/MainTabView.swift) observes the router and switches selection (.more for wallet/deposit, .home for everything else). [HomeView](NeoAstro/Features/Home/HomeView.swift) consumes `freeAsk`, `astrologerProfile`, `chatWith`, `notifications`. [WalletView](NeoAstro/Features/Wallet/WalletView.swift) consumes `deposit(amount:)` (pre-fills the amount field + focuses it). **Batch 3 close-out:** [EditProfileView](NeoAstro/Features/Account/EditProfileView.swift) now has a real `PhotosPicker` overlaid on the avatar with upload progress, error surfacing, and live preview of the freshly-uploaded URL; [EditProfilePayload](NeoAstro/Models/API/ProfileAPI.swift) gained `profilePictureUrl`; [ProfileService.uploadProfilePic](NeoAstro/Services/ProfileService.swift) now patches the URL through `submit` instead of dropping it. New [InvoicesView](NeoAstro/Features/Wallet/InvoicesView.swift) (list with download chevron) added to [WalletView](NeoAstro/Features/Wallet/WalletView.swift)'s quick-links row alongside Cashback/TDS. New [TransactionFilterSheet](NeoAstro/Features/Wallet/TransactionFilterSheet.swift) (server-driven chip filter with offline fallback list, custom flow layout) presented from a new filter button in the passbook header; passbook re-queries on apply.
- **Batch 4d — Free Ask + Free Chat flows.** New [Models/API/FreeAskAPI.swift](NeoAstro/Models/API/FreeAskAPI.swift) with the 10-case `FreeAskCategory` enum (love, marriage, career, education, health, finance, family, business, children, general — labels + SF Symbols), REST body + local-snapshot types. New [Services/FreeAskService.swift](NeoAstro/Services/FreeAskService.swift) (`submitFreeAsk` REST fallback + `matchFreeChat`). [Realtime/Models/RealtimeEvents.swift](NeoAstro/Realtime/Models/RealtimeEvents.swift) gained `FreeAskSubmittedPayload`, `FreeAskAnsweredPayload`, `FreeAskAstrologerLite`, `AstroFreeAskPriceUpdatePayload`, `FreeAskSubmissionPayload` (outbound), `AnswerViewedPayload` (outbound), `InitiateFreeChatPayload`, `FreeChatWaitlistPayload`, `FreeChatAstroIdPayload`. New [Realtime/handlers/FreeAskEventHandler.swift](NeoAstro/Realtime/handlers/FreeAskEventHandler.swift) handles all six events; wired into `RealtimeStore.dispatch`. [RealtimeStore](NeoAstro/Realtime/RealtimeStore.swift) gained `freeAskSubmissionAck`, `freeAskAnswer`, `freeAskOfferPrices: [String: Int]`, `freeAskLocalSubmission`, `freeChatWaitlistText`, `freeChatAssignedAstroId`, plus `resetFreeAsk()` / `resetFreeChat()` helpers. **Free Ask flow** lands as 4 screens: [SelectFreeQuestionView](NeoAstro/Features/FreeAsk/SelectFreeQuestionView.swift) (Liquid Glass category grid), [FreeAskComposeView](NeoAstro/Features/FreeAsk/FreeAskComposeView.swift) (240-char editor with placeholder + counter, dual-emit socket+REST), [FreeAskWaitingView](NeoAstro/Features/FreeAsk/FreeAskWaitingView.swift) (pulsing hero + animated progress bar driven by `progressBarTime`), [FreeAskAnswersView](NeoAstro/Features/FreeAsk/FreeAskAnswersView.swift) (question + astrologer answer card + recommended-astrologer scroller + next-ask cooldown chip; auto-emits `ANSWER_VIEWD` on appear). [FreeAskFlow](NeoAstro/Features/FreeAsk/FreeAskFlow.swift) wraps the four steps in a NavigationStack with resume-on-reopen logic (closing the sheet mid-wait reopens to the right step based on store state). **Free Chat flow**: [FreeChatWaitingView](NeoAstro/Features/FreeChat/FreeChatWaitingView.swift) calls the REST match on appear, emits `INITIATE_FREE_CHAT` on assignment, and surfaces wait text from `FREE_CHAT_WAITLIST`; [FreeChatFlow](NeoAstro/Features/FreeChat/FreeChatFlow.swift) wraps it in a sheet that's interactive-dismiss-disabled until assignment. [HomeView](NeoAstro/Features/Home/HomeView.swift) gained a `freeActionsRow` (two glass tiles below the hero banner) opening either flow as a sheet, plus `handleFreeAskAstrologerPick(_:)` and `handleFreeChatAssigned(_:)` to route from the closed sheet into the existing chat-confirmation / pendingChatAstrologer pipeline.
- **Batch 4c — Chat attachments (voice + image).** New [ChatMediaService](NeoAstro/Services/ChatMediaService.swift) with shared 2-step presigned upload (`uploadVoiceNote` + `uploadImage`). New `Realtime/Audio/` directory: [AudioRecorder](NeoAstro/Realtime/Audio/AudioRecorder.swift) (`@Observable @MainActor` `AVAudioRecorder` wrapper — mic-permission request, AAC m4a at 22 kHz mono, live metering for the waveform UI, 60 s hard cap, slide-to-cancel-aware `start()` / `stopAndCommit()` / `cancel()`) and [AudioPlayer](NeoAstro/Realtime/Audio/AudioPlayer.swift) (singleton `AVAudioPlayer` wrapper, only one bubble plays at a time, progress observable). [ChatViewModel](NeoAstro/Features/Chat/ChatViewModel.swift) gained `sendVoiceNote(_:)` and `sendImage(_:)` — optimistic insert with local file URL, presigned upload, then `RAISE_QUERY` with `messageType=AUDIO`/`IMAGE` and `mediaUrls`. `ChatMessage` gained `mediaURL`, `audioDurationSeconds`, and `isAudio` / `isImage` helpers. [MessageBubble](NeoAstro/Features/Chat/MessageBubble.swift) split into three content variants (`TextMessageContent` / `AudioMessageContent` / `ImageMessageContent`) sharing a common bubble shell — audio bubble shows a tap-to-play button + 110 pt progress track + duration label; image bubble loads via `AsyncImage` with a sheet-presented Liquid Glass lightbox. [ChatInputBar](NeoAstro/Features/Chat/ChatInputBar.swift) reworked: trailing button morphs send ⇄ mic based on draft state, leading `PhotosPicker` button for image attach, press-and-hold-with-slide-to-cancel gesture on the mic drives the new [VoiceRecorderOverlay](NeoAstro/Features/Chat/VoiceRecorderOverlay.swift) (red-tinted glass capsule with pulsing dot, monospaced timer, 14-bar waveform, slide-to-cancel hint that turns orange past the threshold). Inbound `ANSWER_QUERY` audio/image messages decode media URLs from `audioUrl` / `mediaUrls` and render in the same bubble variants. [ChatView](NeoAstro/Features/Chat/ChatView.swift) owns the `AudioRecorder` and threads it down. [Info.plist](NeoAstro/Resources/Info.plist) gained `NSMicrophoneUsageDescription` + `NSPhotoLibraryUsageDescription`.
- **Batch 4 — Realtime / Socket layer.** First third-party SDK lands: `socket.io-client-swift` (16.1+) wired into [project.yml](project.yml). New `NeoAstro/Realtime/` directory with [SocketEvent](NeoAstro/Realtime/SocketEvent.swift) (string-typed enum of every event), [SocketEnvelope](NeoAstro/Realtime/SocketEnvelope.swift) (the `{ en, data }` codec on `req`/`res` channels), [ReconnectionPolicy](NeoAstro/Realtime/ReconnectionPolicy.swift) (linear 100 ms × 120 + exponential variants), [EventValidation](NeoAstro/Realtime/EventValidation.swift) (porting `EVENTS_REQUIRING_*` / `SKIP_IF_*` from RN), [Models/RealtimeEvents.swift](NeoAstro/Realtime/Models/RealtimeEvents.swift) (typed payload DTOs for chat / call / consult / presence / nudge), and [SocketManager.swift](NeoAstro/Realtime/SocketManager.swift) (the `NeoAstroSocket` actor — handshake with full zupee-expected query params, manual reconnection, `emit` and `emitWithAck` with 3×2s exponential retry, multi-subscriber `AsyncStream<RealtimeEvent>`). Five domain handlers in [Realtime/handlers/](NeoAstro/Realtime/handlers): Connection (sets `isConnected`, force-logout on errorCode 256/257), Chat (CHAT_STARTED → ActiveChat, CHAT_ENDED, ANSWER_QUERY drain queue, ASTRO_TYPING window, LOW_BALANCE synth bubble, WAITLIST_JOINED, CHAT_INITIATION_FAILED), Call (INCOMING_CALL_REQUEST surface, CALL_ACCEPTED/REJECTED/CANCELLED/ENDED clear), Presence (ASTROLOGER_STATUS_UPDATE / WAITTIME_UPDATE / UNAVAILABLE / ONLINE_NOTIFICATION → presence map), Notification (UNREAD_MESSAGES_COUNT, DYNAMIC_NUDGE buffer cap-5). [RealtimeStore](NeoAstro/Realtime/RealtimeStore.swift) (`@Observable @MainActor`) bridges all of this into UI state — `isConnected`, `unreadCount`, `activeChat`, `presence`, `incomingCall`, `inboundMessages`, `astroTypingUntil`. App boot wires it: [NeoAstroApp](NeoAstro/App/NeoAstroApp.swift) injects the store and uses `task(id: auth.stage)` to `start()` on `.authenticated` and `stop()` on `.login` / `.splash`. **Chat feature lands real:** [ChatView](NeoAstro/Features/Chat/ChatView.swift) replaces the old `ConsultChatView` placeholder (deleted), backed by [ChatViewModel](NeoAstro/Features/Chat/ChatViewModel.swift) — optimistic message insert with pending/failed indicators, ack-retry RAISE_QUERY, debounced USER_TYPING, drained ANSWER_QUERY with id-dedup, ASTRO_TYPING indicator, system LOW_BALANCE bubble, end-chat confirmation dialog → END_CHAT emit, in-screen status header with live billing pill. [MessageBubble](NeoAstro/Features/Chat/MessageBubble.swift) (user / astro / system variants with Liquid Glass + tinted glass for outgoing, plus animated `TypingIndicator`), [ChatInputBar](NeoAstro/Features/Chat/ChatInputBar.swift) (vertical-axis text field + glass send button). [HomeView.startChat(with:)](NeoAstro/Features/Home/HomeView.swift) emits INITIATE_CHAT and pushes ChatView; HoroscopeView and SearchOverlayView updated to ChatView too. [IncomingCallView](NeoAstro/Features/Calls/IncomingCallView.swift) — full-screen Liquid Glass surface with pulse rings, accept/reject; mounted at [RootView](NeoAstro/Navigation/RootView.swift) via `.fullScreenCover` bound to `RealtimeStore.incomingCall` (Agora hookup is Batch 4b). **Deferred to Batch 4b** (needs Agora SDK decision): Agora audio/video, voice/image attachments, HUMAN_ANSWER_SEEN, video consultation flow, mode switch, free ask/chat flows, deep-link routing, native call ViewController, ringtone, call duration ticker.

- **Batch 3 — REST-only feature surfaces (Profile / Wallet / Notifications; Helpdesk + KYC skipped per request).** Wallet gained 4 service-layer endpoints (TDS certs + summary, cashback, invoices, transaction filters, convert coins) with three new feature screens — [TransactionDetailView](NeoAstro/Features/Wallet/TransactionDetailView.swift) (glass amount hero + details list + invoice card; pushed from passbook rows), [TDSView](NeoAstro/Features/Wallet/TDSView.swift) (TDS summary card + certificate list with download URLs), [CashbackView](NeoAstro/Features/Wallet/CashbackView.swift) (active-coins hero + offer rows + convert-to-wallet CTA). [WalletView](NeoAstro/Features/Wallet/WalletView.swift) gained a quick-links row for Cashback / TDS and uses a `NavigationStack(path:)` for proper back-navigation. Profile gained service methods for `setUserLocation`, `updateUserExperience`, `updateGAId`, `getRejoinInfo`, plus a 2-step presigned-URL `uploadProfilePic` skeleton (UI pass deferred). Notifications: brand-new [NotificationAPI](NeoAstro/Models/API/NotificationAPI.swift) + [NotificationService](NeoAstro/Services/NotificationService.swift) (push token, list, read, clear, clearAll, nudges, markNudgeShown). New [AppDelegate](NeoAstro/App/AppDelegate.swift) wires APNs via `UIApplicationDelegateAdaptor`: requests auth at launch, uploads device token to `/v1.0/misc/fcmToken`, surfaces foreground banners + tap deep-links. New [NotificationCenterView](NeoAstro/Features/Notifications/NotificationCenterView.swift) (glass row list, swipe-to-clear, confirmation-dialog for clear-all, pulled in via bell icon in HomeView toolbar) and reusable [NudgeBanner](NeoAstro/Features/Notifications/NudgeBanner.swift) component. **Project-config TODO (must be done in Xcode):** add the *Push Notifications* capability to the NeoAstro target.
- **Batch 2 — Auth completion (partial; complete except referral + force-update which were deferred).** Added a real cold-start path: [SplashView](NeoAstro/Features/Splash/SplashView.swift) fires `AppConfigStore.bootstrap()` (parallelizes pre-signup config + user details + post-signup config) then `AuthViewModel.routeAfterBootstrap(...)` chooses among `splash → languagePicker / login / onboarding / authenticated`. `AuthViewModel.Stage` gained `splash`, `languagePicker`, `onboarding` cases; `verifyOTP` now re-bootstraps so post-OTP routing reflects whether the user has filled in birth details. New [LanguageSelectionView](NeoAstro/Features/Onboarding/LanguageSelectionView.swift) (Liquid-Glass tile grid, server-driven languages with hardcoded fallback) persists to `TokenStore.language`; `DeviceInfo.language` now reads the user's pick before falling back to `Locale`. New 4-step [OnboardingView](NeoAstro/Features/Onboarding/OnboardingView.swift) + [OnboardingViewModel](NeoAstro/Features/Onboarding/OnboardingViewModel.swift) (name+gender, DOB, time-with-skip, place) hits `submitAstroUserDetails` + `setOnboardingCompleted`. New [ConfigService](NeoAstro/Services/ConfigService.swift) and [OnboardingService](NeoAstro/Services/OnboardingService.swift); new [ConfigAPI](NeoAstro/Models/API/ConfigAPI.swift) DTOs; `TokenStore` extended with `language` and `onboardingCompleted` keys; `AppLog` gained `config` and `onboarding` categories. **Skipped:** referral code entry, force-update gate (per request).
- **Batch 1 — Foundation pass (complete).** Added `AppTheme` tokens (`surface`, `tightCorner`, `sectionSpacing`, `cardPadding`, `balanceCardGradient`, `avatarPalette(for:)`, `primaryAvatarPalette`). Fixed sheet presentations on `HomeView` and `WalletView` (removed `.presentationBackground(.clear)`, switched to `.presentationDragIndicator(.visible)`). Cleaned `ChatConfirmationSheet` and `JuspayPaymentSheet` bodies (dropped inner `CosmicBackground`, custom drag handles, redundant outer glass wrapper) so system Liquid Glass sheets do their job. Centralized avatar palettes — `AstrologerCard`, `AccountView`, `MoreView`, `ChatConfirmationSheet` now use the `AppTheme` helper instead of duplicated hex string arrays. UI-GUIDELINES migration table updated to reflect the actual screen status. See [.claude/references/UI-GUIDELINES.md § 12](.claude/references/UI-GUIDELINES.md).

## Roll-up

| Status | Count |
|--------|------:|
| ✅ Done | 95 |
| 🟡 Partial | 21 |
| 🟦 Stub | 1 |
| ⏳ TODO | ~106 |
| ❓ Verify | 5 |
| 🚫 Won't port | 2 |

> The iOS app is roughly **10 %** of feature parity with the RN user app. Next big wedges by impact: **Realtime / Socket layer** (unblocks chat + call + consultation) and **Juspay integration** (unblocks deposit). After those, the per-minute chat flow can land end-to-end.

---

## How to use this doc

- Pick a row, change `⏳` → `🟡` while in flight, then `✅` when it matches RN parity.
- For each feature you implement, add the iOS file path to the row.
- Keep this doc the source of truth — don't track parity in PR descriptions.
- For HTTP endpoints needed by a row, see [API-ENDPOINTS.md](.claude/references/API-ENDPOINTS.md).
- For socket events needed by a row, see [SOCKET-EVENTS.md](.claude/references/SOCKET-EVENTS.md).
- For UI conventions (Liquid Glass), see [UI-GUIDELINES.md](.claude/references/UI-GUIDELINES.md).
