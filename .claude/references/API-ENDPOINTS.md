# NeoAstro – HTTP API Endpoints Reference

This is an inventory of every HTTP endpoint the React Native user app (`zupee-rn-astro`) consumes, together with backend service ownership. Use it as the porting checklist for the iOS app.

> **Source of truth.** This doc is derived from `/Users/kamal.dixit/Desktop/neoastro-root/zupee-rn-astro/` and the backend services in the same monorepo. If an endpoint behavior is ambiguous, read the RN call site and the backend controller before guessing.

> **iOS scope.** ✅ = already implemented in `NeoAstro/Services/`. ⏳ = TODO. Status was set as of the snapshot when this file was written; verify before relying on it.

---

## Base URLs & Conventions

| Env | Base URL |
|-----|----------|
| stage | `https://cse-sna-superapp-service.neoastrojoy.com` (see [APIEnvironment.swift](../../NeoAstro/Networking/APIEnvironment.swift)) |
| prod | `https://api.neoastro.com` |

**Auth.** All authenticated calls send the access token in the `authorization` header (raw, no `Bearer ` prefix — see [APIClient.swift](../../NeoAstro/Networking/APIClient.swift)).

**Refresh.** `POST /v1.0/refreshToken` is invoked automatically by `APIClient` on 401. Don't call it from feature code.

**Required headers** (set in `DeviceInfo` / `APIClient`):
- `Platform`, `appversion`, `appname`, `packageName`, `language`, `deviceId`, `ludoUserId`, `x-zupee-env`

**Response envelopes.** Backend returns one of three shapes; `APIClient.send` tries them in order:
1. `{ success, response: { data: T } }`
2. `{ success, response: T }`
3. Direct `T`

---

## 1. Auth / OTP / Login

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/user/requestSignupOtp` | auth.service | no | ✅ | Request OTP for signup / re-auth |
| POST | `/v1.0/auth/authenticateUser` | auth.service | no | ✅ | Authenticate with phone + OTP |
| POST | `/v1.0/refreshToken` | auth.service | yes | ✅ (auto) | Refresh access token (handled by `APIClient`) |
| POST | `/v1.0/auth/verifyTruecallerAuth` | auth.service | no | ⏳ | Verify Truecaller authentication |

**`POST /v1.0/auth/authenticateUser`** — request:
```
{ action, socketType, merchantName, DeviceId, det, ult, lc, languagePreference,
  av, version_code, anov, packageName, gaId, newauth, otp, signupPhoneNumber,
  appsFlyerData, isConsultationCampaign, reauth, lastAccessToken,
  refreshToken, _id, zupeeUserId }
```
response:
```
{ success, _id, accessToken, refreshToken, refreshTokenExpiresAt,
  zupeeUserId, appConfig, postSignupConfig, preSignupConfig, ... }
```

---

## 2. Configuration & Setup

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| GET | `/v1.0/config/preSignUp` | misc.service | no | ⏳ | Pre-signup app config |
| POST | `/v1.0/config/postSignUp` | misc.service | yes | ⏳ | Post-signup config |
| GET | `/v1.0/user/getOnboardingConfigV2` | user.service | yes | ⏳ | Onboarding configuration |
| POST | `/v1.0/user/setOnboardingCompleted` | user.service | yes | ⏳ | Mark onboarding complete |
| GET | `/v1.0/misc/checkForUpdate` | misc.service | yes | ⏳ | App update availability |

---

## 3. Profile / User Data

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| GET | `/v1.0/user/getUserDetails` | user.service | yes | ✅ | Get user profile |
| POST | `/v1.0/user/getUserSettings` | user.service | yes | ✅ | Account settings widgets |
| GET | `/v1.0/profile/viewProfile` | user.service | yes | ✅ | View profile |
| POST | `/v1.0/profile/edit` | user.service | yes | ⏳ | Get edit-profile form data |
| POST | `/v1.0/profile/submit` | user.service | yes | ✅ | Submit profile edits |
| POST | `/v1.0/user/uploadProfilePic` | user.service | yes | ⏳ | Upload profile picture |
| POST | `/v1.0/user/sendAppographyDetails` | user.service | yes | ⏳ | Astrology / horoscope details |
| POST | `/v1.0/user/submitAstroUserDetails` | user.service | yes | ⏳ | Submit astrology questionnaire |
| POST | `/v1.0/user/updateGAId` | user.service | yes | ⏳ | Update Google Advertising ID |
| POST | `/v1.0/user/setUserLocation` | user.service | yes | ⏳ | Set user location (current) |
| POST | `/v1.0/user/setLocation` | user.service | yes | ⏳ | Set user location (deprecated) |
| POST | `/v1.0/user/deleteUserAccount` | user.service | yes | ✅ | Delete account |
| POST | `/v1.0/user/getRejoinInfo` | user.service | yes | ⏳ | Rejoin info (re-auth) |

**`POST /v1.0/user/submitAstroUserDetails`** — request: `{ birthDateTime, birthLocation, birthLatitude, birthLongitude, ... }` — response: `{ success, data }`

---

## 4. Astrologer Discovery & Profile

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| GET | `/v1.0/astrologer/listAstrologers` | echo.service | yes | ✅ | List astrologers (widgets payload) |
| POST | `/v1.0/astrologer/refresh` | echo.service | yes | ⏳ | Refresh astrologer list |
| POST | `/v1.0/astrologer/getProfile` | echo.service | yes | ⏳ | Astrologer profile details |
| GET | `/v1.0/astrologer/getPopupDetails` | echo.service | yes | ⏳ | Astrologer popup modal |
| GET | `/v1.0/astrologer/getAstrologerMetadata` | echo.service | yes | ⏳ | Astrologer metadata |
| GET | `/v1.0/astrologer/reviews` | echo.service | yes | ⏳ | Astrologer reviews |
| POST | `/v1.0/astrologer/rate` | echo.service | yes | ⏳ | Rate astrologer |
| POST | `/v1.0/chat/notifyUser` | echo.service | yes | ⏳ | "Notify me when astrologer is online" |

**`POST /v1.0/astrologer/getProfile`** — request: `{ astroId }` — response: `{ response: { chatHistoryWidget, astrologer: { stories, educationAndCertifications }, dynamicData } }`

---

## 5. Chat / Consultation

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/chat/initiateChat` | echo.service | yes | ⏳ | Initiate chat with astrologer |
| POST | `/v1.0/chat/getHistory` | echo.service | yes | ⏳ | Chat conversation history |
| POST | `/v1.0/chat/getHistoryWithAstrologer` | echo.service | yes | ⏳ | Full chat history with one astrologer |
| POST | `/v1.0/chat/getLiveChatDetails` | echo.service | yes | ⏳ | Active live chat details |
| POST | `/v1.0/chat/end` | echo.service | yes | ⏳ | End chat session |
| POST | `/v1.0/chat/deleteChatHistory` | echo.service | yes | ⏳ | Delete chat with one astrologer |
| POST | `/v1.0/chat/deleteAllChatHistory` | echo.service | yes | ⏳ | Delete all chat history |
| POST | `/v1.0/chat/chatRequested` | echo.service | yes | ⏳ | Chat request notification (WebSocket fallback) |
| POST | `/v1.0/chat/chatCancelled` | echo.service | yes | ⏳ | Chat cancellation notification |
| POST | `/v1.0/chat/getImagePreSignedUrl` | echo.service | yes | ⏳ | Pre-signed URL for image upload |
| POST | `/v1.0/chat/getVoiceNotePreSignedUrl` | echo.service | yes | ⏳ | Pre-signed URL for voice note |
| POST | `/v1.0/chat/getSampleBirthLocation` | echo.service | yes | ⏳ | Sample birth locations |
| POST | `/v2.0/user/getChatQCWidgetData` | user.service | yes | ⏳ | Chat quality-check widget |

**`POST /v1.0/chat/initiateChat`** — request: `{ astroId, birthDate, birthTime, birthPlace, birthLatitude, birthLongitude, minute5Rate }` — response: `{ success, sessionId, socketUrl, encryptionKey }`

> ⚠️ Owner is `echo.service`, not `superapp.service`. `superapp.service` is only a forwarder for these payloads — never let the iOS app talk to it as if it owns chat sessions. See `AGENTS.md` § "Out-of-scope concerns" for the parent-repo rule on this.

---

## 6. Voice / Video Call (Per-Minute & Fixed-Price)

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/call/initiateCall` | echo.service | yes | ⏳ | Initiate voice/video call |
| POST | `/v1.0/call/updateCallStatus` | echo.service | yes | ⏳ | Update call status (ringing, connected, ended) |
| POST | `/v1.0/call/cancelCall` | echo.service | yes | ⏳ | Cancel / reject incoming call |
| GET | `/v1.0/call/getLastCallSession` | echo.service | yes | ⏳ | Last call session info |
| POST | `/v1.0/video-consultation/initiate` | echo.service | yes | ⏳ | Initiate video consultation |
| POST | `/v1.0/video-consultation/active` | echo.service | yes | ⏳ | Active video consultation session |
| GET | `/v1.0/video-consultation/packages` | echo.service | yes | ⏳ | Video consultation packages |
| POST | `/v1.0/video-consultation/end` | echo.service | yes | ⏳ | End video consultation |
| POST | `/v1.0/video-consultation/rate` | echo.service | yes | ⏳ | Rate video consultation |
| POST | `/v1.0/video-consultation/switch-mode` | echo.service | yes | ⏳ | Switch between chat / call modes |
| POST | `/v1.0/video-consultation/switch-mode/cancel` | echo.service | yes | ⏳ | Cancel mode switch |

**`POST /v1.0/call/initiateCall`** — request: `{ astroId, birthDate, birthTime, birthPlace, birthLatitude, birthLongitude }` — response: `{ success, sessionId, callToken, encryptionKey, socketUrl }`

> ⚠️ Per-minute voice and fixed-price video are different products. Per-minute creates a `call_session` first, then the chat session is linked after accept. Fixed-price creates a separate consultation session whose ID is **not** the same as `chatSessionId`. See SOCKET-EVENTS.md for the realtime side.

---

## 7. Free Ask / Free Chat

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/chat/freeAsk` | echo.service | yes | ⏳ | Submit free question (Free Ask) |
| POST | `/v1.0/chat/consult-free-chat/match` | echo.service | yes | ⏳ | Match for Free Chat |

> ⚠️ "Free Ask" and "Free Chat" are two different features. Free Ask = user submits a pre-defined question, multiple astrologers respond. Free Chat = first-chat-free engagement. Don't conflate them.

---

## 8. Horoscope / Panchang

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/chat/getHoroscope` | echo.service | yes | ✅ | Daily / weekly / monthly horoscope |
| POST | `/v1.0/chat/getHoroscopeAstrologer` | echo.service | yes | ⏳ | Horoscope from a specific astrologer |
| GET | `/v1.0/user/getPanchangDetails` | echo.service | yes | ✅ | Panchang (Hindu calendar) |

> Note. Horoscope responds with status `pending` while it is being generated. The RN app and the iOS `HoroscopeService` both retry up to 7× with 5 s backoff.

---

## 9. Wallet / Balance / Coins / TDS

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| GET | `/v1.0/wallet/getWalletScreenData` | wallet.service | yes | ✅ | Wallet screen data |
| POST | `/v1.0/wallet/balance` | wallet.service | yes | ⏳ | Current wallet balance |
| GET | `/v1.0/wallet/fetchActiveCashbackCoins` | wallet.service | yes | ⏳ | Active cashback / coins |
| POST | `/v1.0/payment/convertActualCoins` | payment.service | yes | ⏳ | Convert actual coins to playable coins |
| GET | `/v1.0/wallet/transactionHistory/passbook` | wallet.service | yes | ✅ | Transaction passbook |
| GET | `/v1.0/wallet/transactionHistory/filters` | wallet.service | yes | ⏳ | Passbook filter options |
| GET | `/v1.0/wallet/getInvoices` | wallet.service | yes | ⏳ | Invoices |
| GET | `/v1.0/wallet/tds/getTDSCertificates` | wallet.service | yes | ⏳ | TDS certificates |
| GET | `/v1.0/tds/getUserTdsInfo` | wallet.service | yes | ⏳ | User TDS info |
| GET | `/v1.0/wallet/tds/getTdsCertificationOfQuarter` | wallet.service | yes | ⏳ | TDS cert for a quarter |
| POST | `/v1.0/tds/getTdsTransactionOfQuarter` | wallet.service | yes | ⏳ | TDS transactions for a quarter |

---

## 10. Payment / Checkout / Withdrawal

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/payment/getDepositScreenDataBasedOnAstrologer` | payment.service | yes | ⏳ | Deposit options for a specific astrologer |
| POST | `/v1.0/payment/getDepositScreenData` | payment.service | yes | ⏳ | Deposit screen data |
| POST | `/v1.0/payment/initiateCheckout` | payment.service | yes | ⏳ | Initiate checkout session |
| POST | `/v1.0/payment/v2/checkoutOrder/create` | payment.service | yes | ✅ | Create checkout order (Juspay) |
| POST | `/v1.0/payment/getPaymentConfig` | payment.service | yes | ⏳ | Payment configuration |
| POST | `/v1.0/payment/getCheckoutMetaConfigs` | payment.service | yes | ⏳ | Checkout meta config |
| POST | `/v1.0/payment/quickCheckout` | payment.service | yes | ⏳ | Quick checkout (saved instrument) |
| POST | `/v1.0/payment/checkFraudDetection` | payment.service | yes | ⏳ | Fraud detection check |
| POST | `/v1.0/payment/v2/order/status/deposit` | payment.service | yes | ⏳ | Deposit order status |
| POST | `/v1.0/payment/verifyVpa` | payment.service | yes | ⏳ | Verify UPI VPA |
| POST | `/v1.0/payment/fetchFtwScreenData` | payment.service | yes | ⏳ | First-time withdrawal screen |
| POST | `/v1.0/payment/initializeWithdrawalSession` | payment.service | yes | ⏳ | Initialize withdrawal session |
| POST | `/v1.0/payment/withdrawalDebounceWidgetData` | payment.service | yes | ⏳ | Withdrawal widget data |
| POST | `/v1.0/payment/processWithdrawal` | payment.service | yes | ⏳ | Process withdrawal |
| POST | `/v1.0/payment/getSavedWithdrawalModes` | payment.service | yes | ⏳ | Saved withdrawal modes |
| POST | `/v1.0/payment/payoutToUserBank` | payment.service | yes | ⏳ | Execute payout to bank |
| POST | `/v1.0/user/addUpiId` | payment | yes | ⏳ | Add UPI ID |
| POST | `/v1.0/payment/bank/submit` | payment.service | yes | ⏳ | Submit bank account details |

**`POST /v1.0/payment/initiateCheckout`** — request: `{ astrologerId, promoCode, amount, paymentMethod }` — response: `{ success, orderId, breakdown: { actualAmount, promoDiscount, netAmount }, ... }`

**`POST /v1.0/payment/v2/checkoutOrder/create`** — request: `{ orderId, astroId, paymentMethod, amount, promoCode }` — response: `{ success, juspayOrderId, sessionToken }`

**`POST /v1.0/payment/processWithdrawal`** — request: `{ amount, paymentMethod, vpaId | bankAccountId }` — response: `{ success, transactionId, status }`

---

## 11. Rewards / Coupons / Scratch Cards

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/reward/validateCoupon` | reward.service | yes | ⏳ | Validate coupon code |
| POST | `/v1.0/reward/getBestCoupon` | reward.service | yes | ⏳ | Best available coupon |
| POST | `/v1.0/reward/saveScratchCardData` | reward.service | yes | ⏳ | Save scratch-card reward |

---

## 12. Notifications

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/misc/fcmToken` | misc.service | yes | ⏳ | Update FCM token |
| POST | `/v1.0/misc/getNudgesByScreenName` | misc.service | yes | ⏳ | Nudges for a screen |
| POST | `/v1.0/user/setUserNudgeShown` | user.service | yes | ⏳ | Mark nudge shown |
| GET | `/v1.0/misc/readNotification` | misc.service | yes | ⏳ | Mark notification read |
| POST | `/v1.0/misc/clearNotification` | misc.service | yes | ⏳ | Clear single notification |
| POST | `/v1.0/misc/clearAllNotifications` | misc.service | yes | ⏳ | Clear all notifications |
| GET | `/v1.0/user/getNotificationRequestsDetail` | user.service | yes | ⏳ | Notification requests detail |

> ⚠️ iOS uses APNs, not FCM, but the backend endpoint is named `fcmToken` and accepts an APNs token. Pass the device token verbatim and let the server figure it out.

---

## 13. Helpdesk / Support / Tickets

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v2.0/user/getHelpdeskTopicsAndTickets` | helpdesk.service | yes | ⏳ | Helpdesk topics + user tickets |
| POST | `/v1.0/helpdeskWidget/getHelpdeskWidgetisedHomePage` | helpdesk.service | yes | ⏳ | Helpdesk home widget |
| POST | `/v1.0/user/createNewHelpdeskTicket` | helpdesk.service | yes | ⏳ | Create new ticket |
| POST | `/v1.0/user/getHelpdeskTicket` | helpdesk.service | yes | ⏳ | Ticket details |
| POST | `/v1.0/user/addHelpdeskTicketComment` | helpdesk.service | yes | ⏳ | Add ticket comment |
| POST | `/v1.0/user/uploadHelpdeskAttachment` | helpdesk.service | yes | ⏳ | Upload ticket attachment |
| POST | `/v1.0/user/checkTicketCreationSpam` | helpdesk.service | yes | ⏳ | Spam-limit check |
| POST | `/v1.0/user/getFileUploadPreSignedURL` | helpdesk.service | yes | ⏳ | Pre-signed URL for file upload |
| GET | `/v1.0/user/getHelpdeskTransactionTopics` | helpdesk.service | yes | ⏳ | Transaction help topics |
| GET | `/v1.0/user/getHelpdeskDetailsByTid` | helpdesk.service | yes | ⏳ | Helpdesk details by transaction id |
| POST | `/v1.0/helpdesk/getHelpdeskTransactions` | helpdesk.service | yes | ⏳ | Helpdesk transactions (TDS / GST) |
| POST | `/v1.0/helpdesk/submitCsat` | helpdesk.service | yes | ⏳ | Submit CSAT feedback |
| GET | `/v1.0/helpdesk/getRegisteredTournaments` | helpdesk.service | yes | ⏳ | Registered tournaments |

---

## 14. KYC / Compliance

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/kyc/generateKycOtp` | user.service | yes | ⏳ | Generate KYC OTP |
| POST | `/v1.0/kyc/submitKycOtp` | user.service | yes | ⏳ | Submit KYC OTP |
| POST | `/v1.0/kyc/submitKycAsyncV2` | user.service | yes | ⏳ | Submit KYC async (Aadhaar / PAN) |
| GET | `/v1.0/kyc/getKycDocsV3` | user.service | yes | ⏳ | KYC document requirements |
| POST | `/v1.0/kyc/verifyAadhar` | user.service | yes | ⏳ | Verify Aadhaar |
| POST | `/v1.0/kyc/acceptKycConsent` | user.service | yes | ⏳ | Accept KYC consent |
| POST | `/v1.0/kyc/approveAutoVerifyKyc` | user.service | yes | ⏳ | Approve auto-KYC |
| POST | `/v1.0/kyc/declineAutoVerifyKyc` | user.service | yes | ⏳ | Decline auto-KYC |

---

## 15. Search / Recent Items

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| GET | `/v1.0/user/getRecentSearches` | user.service | yes | ⏳ | Recent astrologer searches |
| POST | `/v1.0/user/addRecentSearch` | user.service | yes | ⏳ | Add to recent search history |
| POST | `/v1.0/user/clearRecentSearches` | user.service | yes | ⏳ | Clear recent searches |

---

## 16. Widget / Home Data

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| GET | `/v1.0/user/getWidgetData` | user.service | yes | ⏳ | Home screen widget data |
| GET | `/v2.0/user/getLivePlayersInfo` | user.service | yes | ⏳ | Live players / astrologers count |

---

## 17. Tournaments / Game (superapp)

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v3.0/super/tournament/listTournaments` | superapp.service | yes | ⏳ | List tournaments |
| POST | `/v3.0/super/tournament/getRecommendation` | superapp.service | yes | ⏳ | Tournament recommendations |
| GET | `/v3.0/super/tournament/getFiltersV3` | superapp.service | yes | ⏳ | Tournament filter options |

> Tournaments are part of the broader Zupee gaming platform. The astrology vertical may not need them — clarify scope before porting.

---

## 18. Campaigns / Misc

| Method | Path | Owner | Auth | iOS | Purpose |
|--------|------|-------|------|-----|---------|
| POST | `/v1.0/super/config/checkCampaignSegmentRTFS` | superapp.service | yes | ⏳ | Campaign segment eligibility |
| POST | `/v1.0/user/redeemReferralCode` | user.service | yes | ⏳ | Redeem referral code |
| POST | `/v1.0/chat/getConsultationReportHtml` | echo.service | yes | ⏳ | Consultation report HTML |
| POST | `/v1.0/userExperience/updateUserExperience` | user.service | yes | ⏳ | Update user experience setting |
| POST | `/v1.0/user/getUserSettings` (already in §3) | user.service | yes | ✅ | (settings widgets) |

---

## Summary

| Bucket | Count | iOS today |
|--------|------:|----------:|
| Auth / OTP | 4 | 3 |
| Configuration | 5 | 0 |
| Profile / User | 14 | 4 |
| Astrologer | 8 | 1 |
| Chat | 13 | 0 |
| Free Ask / Free Chat | 2 | 0 |
| Horoscope / Panchang | 3 | 2 |
| Voice / Video Call | 11 | 0 |
| Wallet | 11 | 2 |
| Payment | 18 | 1 |
| Rewards | 3 | 0 |
| Notifications | 7 | 0 |
| Helpdesk | 13 | 0 |
| KYC | 8 | 0 |
| Search | 3 | 0 |
| Widget / Home | 2 | 0 |
| Tournaments | 3 | 0 |
| Campaigns / Misc | 4 | 0 |
| **Total** | **132** | **13** |

> About 90 % of the RN surface is unimplemented on iOS. Use this table to scope features as you port from `zupee-rn-astro`.

---

## How to add an endpoint to the iOS app

1. Add DTOs to `NeoAstro/Models/API/<Feature>API.swift` (Codable, optionals where the field can be missing).
2. Add a static method to `NeoAstro/Services/<Feature>Service.swift`:
   ```swift
   static func foo(...) async throws -> FooResponse {
       try await APIClient.shared.send(
           Request(path: "/v1.0/foo/bar", method: .POST, body: body),
           as: FooResponse.self
       )
   }
   ```
3. Don't touch `APIClient` — it already handles auth, refresh, headers, and the three envelope shapes.
4. If the endpoint requires a non-standard header, pass it via `Request.extraHeaders`.

See [AGENTS.md – Adding a new endpoint](../../AGENTS.md#adding-a-new-endpoint-recipe) for the full recipe.
