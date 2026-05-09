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
| Splash / cold start | ⏳ | — | `screens/splash/Splash.tsx` | Needs maintenance-mode check + auth stage routing |
| Phone-number login | ✅ | [Features/Auth/LoginView.swift](NeoAstro/Features/Auth/LoginView.swift) | `screens/Login/Login.tsx` | |
| OTP verification | ✅ | [Features/Auth/OTPView.swift](NeoAstro/Features/Auth/OTPView.swift) | `screens/verifyOtp/VerifyOtp.tsx` | Resend countdown + auto-fill done |
| Auth stage state machine | ✅ | [Features/Auth/AuthViewModel.swift](NeoAstro/Features/Auth/AuthViewModel.swift) | `appState` Zustand slice | |
| Token refresh on 401 | ✅ | [Networking/APIClient.swift](NeoAstro/Networking/APIClient.swift) | `src/api/index.ts` | Single in-flight refresh, deduped |
| Truecaller signup | ⏳ | — | `useTrueCallerAuthApi.ts` | Optional; needs SDK |
| Pre-signup config | ⏳ | — | `usePreSignupApi.ts` | |
| Post-signup config | ⏳ | — | `services/AuthService.ts` | |
| Language selection | ⏳ | — | `screens/SelectLanguage` | App is English-only today |
| Onboarding questionnaire (birth details for Kundli) | ⏳ | — | `screens/questionnaire` | Required before chat |
| Mark onboarding complete | ⏳ | — | `setOnboardingCompleted` API | |
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
| Chat confirmation sheet | 🟦 | [Features/Home/ChatConfirmationSheet.swift](NeoAstro/Features/Home/ChatConfirmationSheet.swift) | `home/index.tsx` | Stub; no pricing breakdown |
| Birth-details prompt before chat | ⏳ | — | `chat/getSampleBirthLocation` | |
| Initiate chat (CTA) | ⏳ | — | `INITIATE_CHAT` socket | |
| Chat screen | 🟦 | [Features/Home/ConsultChatView.swift](NeoAstro/Features/Home/ConsultChatView.swift) | `cx/chat/ChatScreen.tsx` | Placeholder file |
| Send text message | ⏳ | — | `RAISE_QUERY` w/ ack-retry | |
| Send voice note | ⏳ | — | `getVoiceNotePreSignedUrl` + `RAISE_QUERY` | Needs `VoiceRecorder` bridge |
| Send image | ⏳ | — | `getImagePreSignedUrl` + `RAISE_QUERY` | |
| Reply / quote message | ⏳ | — | `replyTo` / `repliedAgainst` fields | |
| Receive message | ⏳ | — | `ANSWER_QUERY` socket | |
| Typing indicators (both sides) | ⏳ | — | `USER_TYPING` / `ASTRO_TYPING(_STOP)` | |
| Read receipts | ⏳ | — | `HUMAN_ANSWER_SEEN` | Emit only on actual scroll |
| Recording indicators (astrologer) | ⏳ | — | `ASTRO_RECORDING_*` | |
| Audio playback (mini player) | ⏳ | — | `AudioPlayerModule` bridge | |
| Low-balance system message | ⏳ | — | `LOW_BALANCE_NOTIF` | |
| Payment update banner | ⏳ | — | `UPDATE_PAYMENT` | |
| Recharge CTA from chat | ⏳ | — | `IN_CHAT_RECHARGE_CTA_CLICKED` | |
| End chat | ⏳ | — | `END_CHAT` / `CHAT_ENDED` | |
| Chat history list | ⏳ | — | `screens/conversations/index.tsx` | |
| Per-astrologer chat history | ⏳ | — | `chat/getHistoryWithAstrologer` | |
| Live chat details fetch | ⏳ | — | `chat/getLiveChatDetails` | |
| Delete chat with one astrologer | ⏳ | — | `chat/deleteChatHistory` | |
| Delete all chat history | ⏳ | — | `chat/deleteAllChatHistory` | |
| Waitlist screen | ⏳ | — | `WAITLIST_JOINED` + `screens/waitingScreen` | |
| Incoming chat (astrologer-initiated) | ⏳ | — | `INCOMING_CHAT` | |
| Chat initiation failed modal | ⏳ | — | `CHAT_INITIATION_FAILED` | |

---

## 4. Voice Call (Per-Minute)

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Outgoing call initiation | ⏳ | — | `/v1.0/call/initiateCall` | |
| Incoming call full-screen UI | ⏳ | — | `IncomingCallModule` | iOS needs `IncomingCallViewController` equivalent + CallKit |
| Accept call | ⏳ | — | `CALL_ACCEPTED` + `InitiateChatModule.initiateChat` | |
| Reject call | ⏳ | — | `CALL_REJECTED` | |
| Cancel outgoing call | ⏳ | — | `cancelCall` API | |
| Agora audio engine | ⏳ | — | Agora RTC SDK | First third-party dep — discuss before adding |
| Call status update | ⏳ | — | `INCHAT_CALL_STATUS_UPDATE` | |
| Call ended | ⏳ | — | `CALL_ENDED` | |
| Call initiation failed | ⏳ | — | `CALL_INITIATION_FAILED` w/ recommendations | |
| Last call session | ⏳ | — | `getLastCallSession` | |
| Return-to-call bar | ⏳ | — | persistent footer when in call | |
| Ringtone playback | ⏳ | — | `RingtoneModule` bridge | iOS uses `AVAudioPlayer` |
| Call duration display + balance ticker | ⏳ | — | `timeLeftToChat` | |

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
| Free Ask tab | ⏳ | — | `freeAsk/FreeAskTabWrapper.tsx` | Behind feature flag |
| Select free question | ⏳ | — | `selectFreeQuestion` | Category picker |
| Submit free question | ⏳ | — | `chat/freeAsk` + `FREE_ASK` socket | |
| Live astrologer slider | ⏳ | — | `freeAskSlider` | |
| Wait/progress bar UI | ⏳ | — | `FREE_ASK_SUBMITTED` | |
| View answers (multi-astrologer) | ⏳ | — | `freeAskAnswers/index.tsx` | |
| Mark answer as read | ⏳ | — | `ANSWER_VIEWD` (typo intentional) | |
| Recommended astrologers in answer | ⏳ | — | `FREE_ASK_ANSWERED.recommendedAstrologers` | |
| Free Ask small/large nudge | ⏳ | — | `FREE_ASK_*_NUDGE_CLICKED` | |
| Astro price update (offer) | ⏳ | — | `ASTRO_FREE_ASK_PRICE_UPDATE` | |
| Daily-limit gate | ⏳ | — | server-enforced | |

> Reminder: Free Ask ≠ Free Chat. Don't conflate. Consultation-enabled astrologers ARE eligible for Free Ask.

---

## 7. Free Chat (first-chat-free)

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Match for Free Chat | ⏳ | — | `chat/consult-free-chat/match` | |
| Initiate Free Chat | ⏳ | — | `INITIATE_FREE_CHAT` | |
| Free Chat waitlist | ⏳ | — | `FREE_CHAT_WAITLIST` | |
| Astrologer assigned event | ⏳ | — | `FREE_CHAT_ASTRO_ID` | |

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
| Wallet screen data | ✅ | [Features/Wallet/WalletView.swift](NeoAstro/Features/Wallet/WalletView.swift) | `wallet/index.tsx` | |
| Balance check | 🟡 | WalletView | `useCheckWalletBalance` | Pulled via screen-data only; no direct refresh API yet |
| Transaction passbook | ✅ | [Features/Wallet/WalletViewModel.swift](NeoAstro/Features/Wallet/WalletViewModel.swift) | `txnHistory/TransactionHistory.tsx` | |
| Transaction filters | ⏳ | — | `transactionHistory/filters` | |
| Transaction detail view | ⏳ | — | `txnDetails/TransactionInfo.tsx` | |
| Cashback / coins listing | ⏳ | — | `fetchActiveCashbackCoins`, `cashback/Cashback.tsx` | |
| Convert actual → playable coins | ⏳ | — | `payment/convertActualCoins` | |
| Invoices | ⏳ | — | `wallet/getInvoices` | |
| TDS certificates | ⏳ | — | `wallet/tds/*`, `tds/getUserTdsInfo` | |
| TDS / GST txn history | ⏳ | — | `cx/tdsAndGstTxnScreen` | |
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
| Upload profile picture | ⏳ | — | `uploadProfilePic` | |
| Submit astrology questionnaire | ⏳ | — | `submitAstroUserDetails` | |
| Send appography details | ⏳ | — | `sendAppographyDetails` | |
| Set user location | ⏳ | — | `setUserLocation` (legacy `setLocation` deprecated) | |
| Update GA / advertising id | ⏳ | — | `updateGAId` | |
| Get rejoin info | ⏳ | — | `getRejoinInfo` | |
| User experience setting | ⏳ | — | `userExperience/updateUserExperience` | |

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
| Push notification registration (APNs) | ⏳ | — | iOS uses APNs; backend endpoint is `fcmToken` | |
| Update push token | ⏳ | — | `misc/fcmToken` | |
| Notification center / history | ⏳ | — | `screens/notification/Notification.tsx` | |
| Read notification | ⏳ | — | `misc/readNotification` | |
| Clear single notification | ⏳ | — | `misc/clearNotification` | |
| Clear all notifications | ⏳ | — | `misc/clearAllNotifications` | |
| Notification requests detail | ⏳ | — | `getNotificationRequestsDetail` | |
| In-app nudges (per screen) | ⏳ | — | `getNudgesByScreenName` | |
| Mark nudge shown | ⏳ | — | `setUserNudgeShown` | |
| Astrologer-online system notification | ⏳ | — | `ASTROLOGER_ONLINE_NOTIFICATION` | |
| Unread badge count | ⏳ | — | `UNREAD_MESSAGES_COUNT` + `NRC` | |
| Dynamic nudge banner | ⏳ | — | `DYNAMIC_NUDGE` | |
| Deep-link from notification | ⏳ | — | RN universal links | |

---

## 19. Realtime / Socket Layer

| Feature | iOS | iOS file | RN reference | Notes |
|---------|:---:|----------|--------------|-------|
| Socket.IO Swift client integration | ⏳ | — | `src/socket/AppManager.ts` | First third-party dep (Socket.IO Swift) |
| Connection authenticated handling | ⏳ | — | `CONNECTION_AUTHENTICATED` | |
| Force-logout via socket | ⏳ | — | `CONNECTION_MANAGE` | |
| Notification refresh count | ⏳ | — | `NRC` | |
| User-details sync on reconnect | ⏳ | — | `GET_USER_DETAILS` | |
| Manual reconnection (linear / exponential) | ⏳ | — | `ReconnectionHelper` | Disable Socket.IO's built-in retry |
| Event validation guards | ⏳ | — | `EVENTS_REQUIRING_*` / `SKIP_IF_*` | Port to iOS verbatim |
| Ack-and-retry on `RAISE_QUERY` | ⏳ | — | exponential backoff | |
| `{ en, data }` envelope codec | ⏳ | — | `socket.emit("req", ...)` | |
| Token-in-handshake auth | ⏳ | — | query string params | See SOCKET-EVENTS.md §1 |
| Native bridge: `IncomingCallModule` | ⏳ | — | exists in RN | |
| Native bridge: `ConsultCallModule` | ⏳ | — | exists in RN | |
| Native bridge: `InitiateChatModule` | ⏳ | — | exists in RN | |

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

## Roll-up

| Status | Count |
|--------|------:|
| ✅ Done | 19 |
| 🟡 Partial | 11 |
| 🟦 Stub | 3 |
| ⏳ TODO | ~190 |
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
