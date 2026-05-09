# NeoAstro – Socket.IO Event Reference

This is an inventory of every realtime event the React Native user app (`zupee-rn-astro`) uses, together with backend ownership. Use it as the porting checklist for the iOS realtime layer.

> **Source of truth.** Derived from `/Users/kamal.dixit/Desktop/neoastro-root/zupee-rn-astro/src/socket/AppManager.ts` and the backend handlers in `chat.service`, `superapp.service`, `echo.service`, and friends. If an event's behavior is ambiguous, read those handlers — do not guess.

> **iOS scope.** The iOS app does **not** have a socket layer today. There is no Socket.IO Swift client integrated, no `AppManager` equivalent, and no native call/consultation bridge modules. Everything in this doc is currently TODO. Use it as the spec for the realtime work.

---

## 1. Connection Setup

### Transport

- Single Socket.IO client on the root namespace (`/`).
- Websocket transport only (no long-poll fallback in production).
- Server uses `engine.io v3` protocol; iOS clients must use a compatible Socket.IO client (e.g. `socket.io-client-swift` configured for v3).

### Handshake (query parameters)

The token is **passed in the query string at handshake time**, not in an `Authorization` header.

| Param | Source / value |
|-------|----------------|
| `socketType` | `"MAIN_CLIENT"` |
| `action` | `"SIGN_IN_ACTION"` |
| `accessToken` | JWT bearer token (required) |
| `refreshToken` | for token refresh on reconnect |
| `ue` | user email |
| `un` | user name |
| `ult` | user language / locale |
| `SerialNumber` / `uniqueDeviceId` | prefixed device identifier (`DeviceInfo.prefixedSerialNumber`) |
| `packageName` | `com.neoastro.android` (intentional spoof — see `AGENTS.md`) |
| `app_version`, `version_code` | from `DeviceInfo` |
| `det` / `deviceType` | platform string |
| `anov` | OS version |
| `lc` / `languagePreference` | language code |
| `reauth`, `authenticateWithRestApi` | auth-flow flags |

If "ZupeePP" mode is enabled in dynamic config, additional headers are derived from `getEnvironmentHeaders()` and passed as extra query params.

### Auth lifecycle

- Server validates the JWT in `chat.service/src/classes/eventCases.class.ts` (`validateSocketConnectionWithJWT` middleware).
- Invalid / expired token → server disconnects with one of: `INVALID_TOKEN=800`, `EXPIRED_TOKEN=801`, `NO_TOKEN=802`, `INCORRECT_OTP=256`, `INVALID_REFRESH_TOKEN=257`.
- The RN client refreshes the token via REST (`/v1.0/refreshToken`) before reconnecting if it sees those error codes.

### Message envelope

Every payload is wrapped:

```
client → server :  socket.emit("req", { en: "<EVENT_NAME>", data: <payload> })
server → client :  socket.emit("res", { en: "<EVENT_NAME>", data: <payload> })
```

Acks are supported: `socket.emit("req", {...}, ack => {})`. Critical client → server emits use ack with retry — see `RAISE_QUERY` below.

### Reconnection

- The RN app does **not** rely on Socket.IO's built-in reconnection (`reconnection=false`).
- Custom logic in `ReconnectionHelper`:
  - Linear backoff (default): 100 ms initial, up to 120 attempts.
  - Exponential backoff (optional): base 2, factor 4, up to 4 attempts.
- Reconnect triggers: NetInfo "online" event, `AppState` foreground transition, manual retry CTA.

### Singleton

- One `SocketManager` instance per app lifecycle, owned by `AppManager` (`src/socket/AppManager.ts:166`).
- Destroyed on logout via `removeAppManager()`.

---

## 2. Connection Lifecycle

| Event | Direction | Payload (keys) | Backend | Purpose |
|-------|-----------|----------------|---------|---------|
| `CONNECTION_AUTHENTICATED` | server→client | `{ errorCode? }` | echo.service – `signup.class.ts` | After JWT validation. If `errorCode` present (256/257), trigger logout; else fire native `SOCKET_CONNECTED`. |
| `CONNECTION_MANAGE` | server→client | (empty) | chat.service | Server forces immediate logout (admin / abuse). Rare. |
| `NRC` | server→client | `{ ct }` | chat.service | "Notification refresh count" — `ct` is unread badge count. |
| `GET_USER_DETAILS` | server→client | `{ response: { userDetail: {...} } }` | echo.service | Profile sync on reconnect. |

---

## 3. Chat Lifecycle

### Per-minute and fixed-price differ

- **Per-minute** chat starts via `INITIATE_CHAT` (or astrologer-initiated `INCOMING_CHAT`). Backend returns `CHAT_STARTED` with `isFixedPriceConsultation: false`.
- **Fixed-price** consultation chat is opened via `CONSULTATION_CHAT_STARTED` inside an active consult session (see § 5). Backend returns `CHAT_STARTED` with `isFixedPriceConsultation: true` and `consultationType: "quick_consult"`.
- Always discriminate on `isFixedPriceConsultation` (boolean) or `consultationType` (string). Never assume the flow from event name alone.

### Initiation

| Event | Direction | Payload (keys) | Backend handler | Purpose |
|-------|-----------|----------------|-----------------|---------|
| `CHAT_REQUESTED` | client→server | `astroId, isClickedFromFreeAsk` | `chat.service/.../chat.requested.service.ts` | User clicks chat CTA — may queue waitlist or immediate accept. |
| `INITIATE_CHAT` | client→server | `astroId, continueSession` | `chat.service/.../initiate.chat.service.ts` (SQS) | Explicit chat start. Backend creates `chat_session`, then emits `CHAT_STARTED`. |
| `WAITLIST_JOINED` | server→client | `astrologerId, isNotificationSubscribed, waitlistHeading, displayText, timeOut` | `chat.service/.../waitlist.service.ts` | User added to astrologer's waitlist; "Notify Me" banner if astrologer offline. |
| `INCOMING_CHAT` | server→client | `astrologerId, astrologerName, astrologerImage, title, timeOut, expiryTime` | `chat.service/.../incoming.chat.service.ts` | Astrologer-initiated chat — show accept/reject UI. |
| `CHAT_STARTED` | server→client | `chatId, astroId, userId, callSessionId?, isFixedPriceConsultation, consultationType, ts, timeLeft, suggestedQuestions` | `chat.service/.../initiate.chat.service.ts` | Session officially open. Navigate to chat screen, init message store. |
| `CHAT_INITIATION_FAILED` | server→client | `astroId, balanceInsufficient, heading, subHeading, buttonText, NAVIGATE_TO_SCREEN, isFixedPriceConsultation` | `chat.service/.../initiation.failed.service.ts` | Chat failed (no balance, astro offline, etc.). |

**`CHAT_STARTED` sample**
```
{
  chatId, astroId, userId,
  callSessionId,                 // present only for per-minute voice chats
  isFixedPriceConsultation,      // discriminator
  consultationType,              // "quick_consult" | "per_minute"
  ts, timeLeft,
  suggestedQuestions, chatHistory?
}
```

### In-progress (per-minute)

| Event | Direction | Payload (keys) | Backend | Purpose |
|-------|-----------|----------------|---------|---------|
| `RAISE_QUERY` | client→server | `chatId, astroId, message, messageType, sequenceId, mediaUrls?, audioDuration?, replyTo?, originalMessage?` | `chat.service/.../message.service.ts` | User sends text/audio/image. **Ack-and-retry** with exponential backoff (3 retries, 2 s base). |
| `ANSWER_QUERY` | server→client | `_id, message, messageType, createdAt, sequenceId, seen, astroId, audioUrl?, audioDuration?, mediaUrls?, repliedAgainst?` | `chat.service/.../message.service.ts` | Astrologer reply. Increments unread; relayed to ConsultFreeChat if open. |
| `USER_TYPING` | client→server | `astroId, chatId, typingTimeout?` | `chat.service/.../typing.service.ts` | User is typing — debounce on input focus. |
| `ASTRO_TYPING` | server→client | `astrologerId, typingTimeout` | `chat.service/.../typing.service.ts` | Astrologer is typing — show indicator (default 120 s timeout). |
| `ASTRO_TYPING_STOP` | server→client | `astrologerId` | `chat.service/.../typing.service.ts` | Astrologer stopped typing. |
| `HUMAN_ANSWER_SEEN` | client→server | `chatId, sequenceId` | `chat.service/.../message.service.ts` | Read receipt — emitted only when user actually scrolls into view. |
| `LOW_BALANCE_NOTIF` | server→client | `astroId, messageType, ...` | `chat.service/.../user.low.balance.service.ts` | System message injected into chat. |
| `UPDATE_PAYMENT` | server→client | `chatEndTime` | payment.service | Payment state updated; refresh countdown. |
| `BALANCE_UPDATED` | server→client | `{}` | wallet.service | Wallet balance changed — refetch. |

### End

| Event | Direction | Payload (keys) | Backend | Purpose |
|-------|-----------|----------------|---------|---------|
| `END_CHAT` | client→server | `chatId, endedBy` | `chat.service/.../chat.end.service.ts` | User ends chat. Emit only once per screen lifetime (guard with a flag). |
| `CHAT_ENDED` | server→client | `callSessionId?, astroId, chatId` | `chat.service/.../chat.end.service.ts` | Chat closed (user, astrologer, or timeout). Reset state. |

---

## 4. Voice Call (Per-Minute)

| Event | Direction | Payload (keys) | Backend | Purpose |
|-------|-----------|----------------|---------|---------|
| `INCOMING_CALL_REQUEST` | server→client | `astroId, userName, userImage, token, channelName, callSessionId, expiryTime, timeOut, isVoiceCall` | `chat.service/.../in.chat.call.service.ts` | Astrologer initiates voice call. Includes Agora credentials. On Android → native call UI; on iOS → full-screen native call screen. |
| `CALL_ACCEPTED` | server→client | `callSessionId, astroId, timeLeftToChat` | `chat.service/.../in.chat.call.accepted.service.ts` | User accepted. iOS transitions native call screen to ONGOING; native bridge `InitiateChatModule.initiateChat(astroId, callSessionId)` persists session. |
| `CALL_REJECTED` | server→client | `astroId, callSessionId, currentCallStatus, message` | `chat.service/.../in.chat.call.rejected.service.ts` | Rejected by user or auto-reject timeout fired. Stop Agora, dismiss UI. |
| `CALL_CANCELLED` | server→client | `astroId, callSessionId, zupeeUserId` | `chat.service/.../call.cancelled.service.ts` | Astrologer cancelled before user accepted. Only acted on if `callStatus == INCOMING`. |
| `CALL_ENDED` | server→client | `callSessionId, astroId` | `chat.service/.../call.ended.service.ts` | Call hung up / network drop / duration expired. |
| `CALL_INITIATION_FAILED` | server→client | `astroId, callSessionId, heading, subHeading, buttonText, recommendedAstrologers[]` | `chat.service/.../call.initiation.failed.service.ts` | No Agora slot, balance, etc. Show error modal with recommendations. |
| `INCHAT_CALL_STATUS_UPDATE` | server→client | `astroId, chatId, callSessionId, status` | `chat.service/.../in.chat.call.status.service.ts` | Call sub-status during active call+chat. Locate matching message by `callSessionId` and update `callSessionStatus`. |

> ⚠️ Per-minute voice creates a `call_session` first; the `chat_session` is linked **after** `CALL_ACCEPTED` via `InitiateChatModule.initiateChat(astroId, callSessionId)`. If that step is skipped, the astrologer side never gets biodata and end-of-call propagation breaks.

---

## 5. Video / Fixed-Price Consultation ("quick_consult")

| Event | Direction | Payload (keys) | Backend | Purpose |
|-------|-----------|----------------|---------|---------|
| `VIDEO_CONSULT_ACCEPTED` | server→client | `sessionId, agoraChannelName, agoraToken, agoraUid, scheduledEndAt, chatSessionId, astrologerId, consultationType, endNudgeBeforeMinutes, gracePeriodSeconds` | superapp.service | Astrologer accepted quick_consult. Native bridge: `ConsultCallModule.consultationAccepted(...)`. Navigate to ConsultChatScreen. |
| `VIDEO_CONSULT_REJECTED` | server→client | `sessionId, reason` | superapp.service | Astrologer rejected. Bridge: `ConsultCallModule.consultationRejected(...)`. |
| `VIDEO_CONSULT_TIMED_OUT` | server→client | `sessionId` | superapp.service | Request expired. |
| `VIDEO_CONSULT_ENDED` | server→client | `sessionId, userId, astrologerId, callDurationSeconds, endChat` | superapp.service | Session ended. If `endChat == true`, also clear chat state. |
| `CONSULTATION_CHAT_STARTED` | server→client | `chatId, astrologerId, chatHistory[], timeLeft, suggestedQuestions[]` | superapp.service | Init the in-consult chat history + countdown. |
| `CONSULTATION_MODE_SWITCH_ACCEPTED` | server→client | `newSessionId, sourceSessionId, scheduledEndAt, channelName, userToken, appId, toMode, fromMode, endNudgeBeforeMinutes, gracePeriodSeconds` | superapp.service | User switched chat ↔ voice ↔ video mid-session. If `fromMode == chat`, launch new native call; else update in place. |
| `CONSULTATION_MODE_SWITCH_REJECTED` | server→client | `sourceSessionId, fromMode, toMode` | superapp.service | Mode switch denied. |
| `CONSULTATION_MODE_SWITCH_CANCELLED` | server→client | `fromMode` | superapp.service | Mode switch cancelled. |
| `CONSULTATION_REPORT_READY` | server→client | `chatSessionId, astroId, consultationReportData { meta: { generatedAt }, ... }` | superapp.service | AI-generated post-consult summary. Inject as system message into chat. |
| `INITIATE_CONSULT_FREE_CHAT` | client→server | `astroId, chatId, guidance, guidanceLabel` | superapp.service | Free-chat-within-consult. `guidance` = user's initial message. |
| `CONSULT_FREE_CHAT_STARTED` | server→client | `{}` | superapp.service | Free-chat segment opened. Surfaced via `DeviceEventEmitter` in RN. |
| `END_CONSULT_FREE_CHAT` | client→server | `chatId, endedBy` | superapp.service | End free-chat segment (currently commented out in RN). |
| `CONSULT_FREE_CHAT_ENDED` | server→client | `{}` | superapp.service | Free-chat segment closed. |

> ⚠️ In fixed-price voice/video, `sessionId` is the **consultation** session id, **not** `chatSessionId`. They are separate concepts. Don't reuse one as the other.

---

## 6. Free Ask (async Q&A)

| Event | Direction | Payload (keys) | Backend | Purpose |
|-------|-----------|----------------|---------|---------|
| `FREE_ASK` | client→server | (form data) | `chat.service/.../free.ask.service.ts` | User submits a free question. |
| `FREE_ASK_SUBMITTED` | server→client | `astrologers[], astrologerCount, progressBarCount, progressBarTime, text, acceptedText` | `chat.service/.../free.ask.service.ts` | Question accepted; show waitlist + progress bar. |
| `FREE_ASK_ANSWERED` | server→client | `qaAskedExpiryTime, questionText, recommendedAstrologers[], viewAllText, askNextOneInText, offerValidText, astrologers[]` | `chat.service/.../free.ask.service.ts` | Answer ready; show answer + recommendations. |
| `ANSWER_VIEWD` *(typo intentional)* | client→server | `astroId` | chat.service | Mark answer as read; decrement unread. |
| `FREE_ASK_SMALL_NUDGE_CLICKED` | client→server | `{}` | notification.service | Analytics. |
| `FREE_ASK_LARGE_NUDGE_CLICKED` | client→server | `{}` | notification.service | Analytics. |
| `ASTRO_FREE_ASK_PRICE_UPDATE` | server→client | `astrologerId, discountedPrice, timestamp` | chat.service | Astrologer price updated for this question (offer). |

> ⚠️ "Free Ask" ≠ "Free Chat". Free Ask is a one-shot Q&A submitted to multiple astrologers; Free Chat is a first-chat-free engagement. Consultation-enabled astrologers ARE eligible for Free Ask. Don't conflate the two when porting.

---

## 7. Free Chat

| Event | Direction | Payload (keys) | Backend | Purpose |
|-------|-----------|----------------|---------|---------|
| `INITIATE_FREE_CHAT` | client→server | `zupeeUserId` | chat.service | Start a free chat (no balance deduct, time-limited). |
| `FREE_CHAT_WAITLIST` | server→client | `text` | chat.service | Waitlist message; navigate to waiting screen. |
| `FREE_CHAT_ASTRO_ID` | server→client | `astroId` | chat.service | Astrologer assigned. |

---

## 8. Presence / Status

| Event | Direction | Payload (keys) | Backend | Purpose |
|-------|-----------|----------------|---------|---------|
| `ASTROLOGER_STATUS_UPDATE` | server→client | `message: { astrologerId, chatStatus?, status?, statusStyle?, waitTime?, availability?, voiceStatus?, consultationCurrentState?, supportedConsultationTypes? }` | `chat.service/.../astrologer.status.service.ts` | Bulk status update — online/busy/away/offline + consultation availability. |
| `ASTROLOGER_WAITTIME_UPDATE` | server→client | `message: { astroId, displayText, extimatedTimestamp, backgroundColor, waitTimeInMins, waitlistUsers, status }` | `chat.service/.../waitlist.service.ts` | Per-user wait estimate. Replace `{PLACEHOLDER}` in `displayText`. |
| `ASTROLOGER_UNAVAILABLE` | server→client | `astrologerId` | `chat.service/.../astrologer.unavailable.service.ts` | Astrologer dropped offline while user waitlisted. |
| `ASTROLOGER_ONLINE_NOTIFICATION` | server→client | `astrologerId, name, image, subtext, price, timestamp` | notification.service | Astrologer came online — fire system notification. |
| `UPDATE_WAITTIME` | server→client | `displayText, estimatedTimestamp, backgroundColor, waitTimeInMins` | chat.service | Periodic wait-time refresh. |
| `EXIT_WAITLIST` | server→client | `astrologerId` | chat.service | User left waitlist or capacity full. |
| `REFRESH_ASTROLOGERS_STATUS` | server→client | `[{ astroId, status, waitTime, ... }]` | chat.service | Batch status refresh. |

> Discrimination tip: per-minute UI checks `chatStatus`; consultation UI checks `consultationCurrentState`. Don't read both indiscriminately.

---

## 9. Recording / Media

| Event | Direction | Payload | Backend | Purpose |
|-------|-----------|---------|---------|---------|
| `USER_RECORDING_STARTED` | client→server | `astroId, chatId` | chat.service | User started voice-message recording. |
| `USER_RECORDING_STOPPED` | client→server | `astroId, chatId` | chat.service | User finished recording (audio sent via `RAISE_QUERY` with `messageType=AUDIO`). |
| `ASTRO_RECORDING_STARTED` | server→client | `{}` | chat.service | Show "Astrologer is recording" indicator. |
| `ASTRO_RECORDING_STOPPED` | server→client | `{}` | chat.service | Hide indicator; audio message incoming. |

---

## 10. Notifications / Unread / Nudges

| Event | Direction | Payload | Backend | Purpose |
|-------|-----------|---------|---------|---------|
| `UNREAD_MESSAGES_COUNT` | server→client | `unreadMessages` | chat.service | Total unread across all astrologers. |
| `DYNAMIC_NUDGE` | server→client | `astroId, userZuid, nudgeType, data: { text }` | notification.service | Contextual nudge (e.g. "Switch to voice for free"). |
| `IN_CHAT_RECHARGE_CTA_CLICKED` | client→server | `{}` | analytics | Recharge CTA clicked while in low-balance chat. |

---

## 11. Native bridge calls (iOS targets)

These are not socket events themselves; they are native module calls the RN app fires **in response** to socket events. The iOS app will need equivalents.

### Per-minute call (target: `IncomingCallModule`)

| Triggered by | Method | Args |
|--------------|--------|------|
| `INCOMING_CALL_REQUEST` | `startIncomingCall(...)` | `{ callSessionId, astroId, callerName, callerImage, autoRejectTimeoutMs, initialState: "INCOMING" }` |
| `CALL_ACCEPTED` | `transitionToOngoing(...)` | `{ token, channelName, chatId, timeLeftToChat }` |
| `CALL_INITIATION_FAILED` / `CALL_REJECTED` / `CALL_CANCELLED` / `CALL_ENDED` | `dismissCallScreen(reason)` | `"remote"` / `"timeout"` / `"user"` |

### Quick consult (target: `ConsultCallModule`)

| Triggered by | Method | Args |
|--------------|--------|------|
| `VIDEO_CONSULT_ACCEPTED` | `consultationAccepted(...)` | `{ consultationSessionId, channelName, token, uid, scheduledEndAt, endNudgeBeforeMinutes, gracePeriodSeconds }` |
| `VIDEO_CONSULT_REJECTED` / `VIDEO_CONSULT_TIMED_OUT` | `consultationRejected({ sessionId, reason })` | — |
| `CONSULTATION_MODE_SWITCH_ACCEPTED` | `rejoinConsultation(...)` if `fromMode == chat`, else `modeSwitchAccepted(...)` | Agora creds + scheduling |

### Per-minute chat (target: `InitiateChatModule`)

| Triggered by | Method | Args |
|--------------|--------|------|
| `CALL_ACCEPTED` | `initiateChat(astroId, callSessionId)` | persists call→chat linkage |

> The iOS app currently has none of these modules. Building them is part of the per-minute and consultation roll-outs.

---

## 12. Critical caveats

1. **Payload key casing matters.** Server sends camelCase (`astroId`, `chatId`); the validator drops events whose key set doesn't match. Don't rename fields client-side.

2. **Event validation guards.** Several events are silently dropped if:
   - the payload's `astrologerId` ≠ currently selected/active astrologer (`EVENTS_REQUIRING_*_ASTRO_ID_VALIDATION`),
   - the chat status is in the wrong state for the event (`EVENTS_SKIP_IF_IN_PROGRESS` / `EVENTS_SKIP_IF_NOT_IN_PROGRESS`).

   Reproduce these guards in the iOS handler — they exist to prevent stale events from clobbering current state.

3. **`isFixedPriceConsultation` is the discriminator.** Anywhere you see `CHAT_STARTED`, `CHAT_INITIATION_FAILED`, or `CHAT_ENDED`, branch on `isFixedPriceConsultation`. Per-minute → helpdesk-style chat screen. Fixed-price → consult chat screen.

4. **`sessionId` vs `chatSessionId`.** In fixed-price voice/video they are different ids. **Never** assume `sessionId === chatSessionId` outside the fixed-price chat-only path.

5. **Ack-and-retry on `RAISE_QUERY`.** Critical messages use exponential backoff (3 retries, 2 s base, 2× factor). Tunable via dynamic config. iOS must replicate this — fire-and-forget will silently drop messages on flaky networks.

6. **`HUMAN_ANSWER_SEEN`** is **not** auto-emitted on chat-screen focus. Emit only when the user has actually scrolled to the high-sequence message. Otherwise read receipts will be dishonest.

7. **`CONSULTATION_REPORT_READY`** arrives minutes after the call ended. Be ready to inject a system message into a chat session that already looks "closed".

8. **Reconnect storms.** On NetInfo flap, the RN app reconnects manually with linear backoff. Do not enable Socket.IO's built-in reconnection alongside a custom reconnect helper — they fight.

---

## 13. Suggested iOS architecture (sketch, not yet implemented)

```
NeoAstro/
└── Realtime/
    ├── SocketManager.swift            # actor wrapping Socket.IO Swift client
    ├── SocketEnvelope.swift           # { en, data } codec
    ├── SocketEvent.swift              # enum of every event name (string-typed)
    ├── EventValidation.swift          # ports the EVENTS_REQUIRING_* / SKIP_IF_* guards
    ├── ReconnectionPolicy.swift       # linear / exponential backoff
    └── handlers/
        ├── ChatEventHandler.swift     # CHAT_STARTED, CHAT_ENDED, ANSWER_QUERY, ...
        ├── CallEventHandler.swift     # INCOMING_CALL_REQUEST, CALL_ACCEPTED, ...
        ├── ConsultEventHandler.swift  # VIDEO_CONSULT_*, CONSULTATION_*
        ├── PresenceEventHandler.swift # ASTROLOGER_STATUS_UPDATE, ASTROLOGER_WAITTIME_UPDATE, ...
        └── NotificationEventHandler.swift
```

`SocketManager` is the only owner of the socket, lives at app level (similar to `TokenStore`), and pumps events into typed handlers. ViewModels subscribe to handler-published `AsyncStream`s rather than touching the socket directly.

Native call/consult bridges (the equivalents of `IncomingCallModule`, `ConsultCallModule`, `InitiateChatModule`) will need to be built when those flows land.

---

## 14. Backend service ownership at a glance

| Service | Emits to user | Consumes from user |
|---------|---------------|--------------------|
| **chat.service** | CHAT_STARTED, ANSWER_QUERY, CHAT_ENDED, CHAT_INITIATION_FAILED, INCOMING_CHAT, WAITLIST_JOINED, LOW_BALANCE_NOTIF, ASTRO_TYPING(*), UPDATE_WAITTIME, ASTROLOGER_(UNAVAILABLE / STATUS_UPDATE / WAITTIME_UPDATE), ASTRO_RECORDING_*, UNREAD_MESSAGES_COUNT, INCOMING_CALL_REQUEST, CALL_(ACCEPTED / REJECTED / CANCELLED / ENDED / INITIATION_FAILED), INCHAT_CALL_STATUS_UPDATE, FREE_ASK_*, FREE_CHAT_*, REFRESH_ASTROLOGERS_STATUS, DYNAMIC_NUDGE | INITIATE_CHAT, CHAT_REQUESTED, RAISE_QUERY, END_CHAT, USER_TYPING, USER_RECORDING_*, HUMAN_ANSWER_SEEN, ANSWER_VIEWD, EXIT_WAITLIST, FREE_ASK*, INITIATE_FREE_CHAT, INITIATE_CONSULT_FREE_CHAT, IN_CHAT_RECHARGE_CTA_CLICKED |
| **superapp.service** | VIDEO_CONSULT_(ACCEPTED / REJECTED / TIMED_OUT / ENDED), CONSULTATION_CHAT_STARTED, CONSULTATION_MODE_SWITCH_*, CONSULTATION_REPORT_READY, CONSULT_FREE_CHAT_(STARTED / ENDED) | (mostly via REST + native bridge, not socket emits) |
| **echo.service** | CONNECTION_AUTHENTICATED, GET_USER_DETAILS, NRC, CONNECTION_MANAGE | — |
| **notification.service** | ASTROLOGER_ONLINE_NOTIFICATION, DYNAMIC_NUDGE | — |
| **wallet.service** | BALANCE_UPDATED | — |
| **payment.service** | UPDATE_PAYMENT | — |

---

## 15. Quick lookup — event by domain

```
Connection      : CONNECTION_AUTHENTICATED, CONNECTION_MANAGE, NRC, GET_USER_DETAILS
Chat init       : CHAT_REQUESTED → INITIATE_CHAT → CHAT_STARTED | CHAT_INITIATION_FAILED
                  WAITLIST_JOINED, INCOMING_CHAT
Chat run        : RAISE_QUERY ↔ ANSWER_QUERY, USER_TYPING ↔ ASTRO_TYPING(/STOP),
                  HUMAN_ANSWER_SEEN, LOW_BALANCE_NOTIF, UPDATE_PAYMENT, BALANCE_UPDATED
Chat end        : END_CHAT → CHAT_ENDED
Voice (per-min) : INCOMING_CALL_REQUEST → CALL_ACCEPTED | CALL_REJECTED | CALL_CANCELLED
                  CALL_ENDED, CALL_INITIATION_FAILED, INCHAT_CALL_STATUS_UPDATE
Consult         : VIDEO_CONSULT_(ACCEPTED / REJECTED / TIMED_OUT / ENDED),
                  CONSULTATION_CHAT_STARTED, CONSULTATION_MODE_SWITCH_(ACCEPTED / REJECTED / CANCELLED),
                  CONSULTATION_REPORT_READY,
                  INITIATE_CONSULT_FREE_CHAT → CONSULT_FREE_CHAT_STARTED, END_CONSULT_FREE_CHAT → CONSULT_FREE_CHAT_ENDED
Free Ask        : FREE_ASK → FREE_ASK_SUBMITTED → FREE_ASK_ANSWERED, ANSWER_VIEWD,
                  FREE_ASK_*_NUDGE_CLICKED, ASTRO_FREE_ASK_PRICE_UPDATE
Free Chat       : INITIATE_FREE_CHAT → FREE_CHAT_WAITLIST → FREE_CHAT_ASTRO_ID
Presence        : ASTROLOGER_STATUS_UPDATE, ASTROLOGER_WAITTIME_UPDATE, ASTROLOGER_UNAVAILABLE,
                  ASTROLOGER_ONLINE_NOTIFICATION, UPDATE_WAITTIME, EXIT_WAITLIST,
                  REFRESH_ASTROLOGERS_STATUS
Recording       : USER_RECORDING_(STARTED / STOPPED), ASTRO_RECORDING_(STARTED / STOPPED)
Notifications   : UNREAD_MESSAGES_COUNT, DYNAMIC_NUDGE
```

Use this list as the porting checklist — every event that does not yet have an iOS handler is unfinished work.
