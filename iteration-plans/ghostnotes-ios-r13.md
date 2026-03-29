# Ghost Notes — R13: System Integration, Widgets & Apple Watch

## Theme
"Ghost Notes everywhere." R13 embeds Ghost Notes into the Apple ecosystem — home screen widgets, Siri shortcuts, and an Apple Watch companion for reading on the go.

---

## Feature Breakdown

### 1. WidgetKit Home Screen Widgets
**Goal:** Quick-glance reading stats and article previews without opening the app

- [ ] **Small widget (2×2):** Shows reading streak (flame icon + day count) + last article title
- [ ] **Medium widget (4×2):** Reading streak + top 3 unread articles with domain favicons
- [ ] **Large widget (4×4):** Reading streak + reading stats (week) + top 5 unread with tap-to-open
- [ ] Widget uses `WidgetKit` + `TimelineProvider`
- [ ] Deep link from widget → opens specific article in app
- [ ] Widget refresh via App Group shared UserDefaults (no background fetch needed)
- [ ] Widget configuration: choose which collection feeds the widget

### 2. Siri Shortcuts & App Intents
**Goal:** Save articles and check your reading queue hands-free

- [ ] **"Save to Ghost Notes" Shortcut action** — takes URL as input
  - Works from Safari share sheet, Siri ("Save this link to Ghost Notes")
  - Uses `AddArticleIntent` / `AppIntent` protocol
- [ ] **"What's on my reading list?" Shortcut action**
  - Returns count of unread articles + titles
  - Works with Siri ("Hey Siri, what's on my Ghost Notes reading list?")
- [ ] **"Mark current article as read" Shortcut action**
  - From share sheet or from within Ghost Notes
- [ ] Shortcuts app gallery integration (pre-built shortcuts)
- [ ] Automation triggers: "When I save an article from Safari, add it to Ghost Notes"

### 3. Apple Watch Companion App
**Goal:** Read articles and track streaks from your wrist

- [ ] Watch app target (`GhostNotesWatch`) with `watchOS` platform
- [ ] **Watch UI (SwiftUI + WatchKit):**
  - Home screen: reading streak + unread count
  - Article list (compact — title + domain + read time)
  - Reading view: scrollable article body text (watch-optimized font size)
  - Mark as read button
- [ ] **Watch-to-iPhone sync:** Uses WatchConnectivity (`WCSession`)
  - Articles synced to Watch via shared App Group container
  - Reading progress syncs back to iPhone on reconnect
- [ ] **Watch complications:**
  - Circular (streak count), Rectangular (streak + unread count), Corner (flame)
- [ ] Glance: current streak + next article title

### 4. Spotlight Search Integration
**Goal:** Find articles from the iOS/macOS Spotlight search

- [ ] `CSSearchableIndex` integration for all articles
- [ ] Article indexed on save: title, domain, description, saved date
- [ ] `CSSearchableItemAttributeSet` with article-specific metadata
- [ ] Deep link: tap search result → opens Ghost Notes directly to that article
- [ ] Re-index on article update/delete
- [ ] Works on both iOS and macOS Spotlight

### 5. Focus Mode / Live Activities
**Goal:** Seamlessly track reading progress during Focus sessions

- [ ] **Live Activity:** When reading an article, show reading progress on Lock Screen
  - Article title + reading progress bar + estimated time remaining
  - Uses `ActivityKit` (`LiveActivity` + `ContentState`)
- [ ] **Focus Filter:** Ghost Notes can filter notifications during a custom "Reading" Focus mode
- [ ] Lock Screen widget showing current reading article + progress (compact Live Activity alternative)

---

## Technical Approach

- **Widgets:** `WidgetKit` with `TimelineProvider`. Data via App Group UserDefaults (`group.com.tomalabs.ghostnotes`).
- **App Intents:** `AppIntents` framework (iOS 16+). No SiriKit needed — pure App Intents.
- **Watch App:** Separate `GhostNotesWatch` target. `WatchConnectivity` for phone↔watch sync. WatchOS 10+.
- **Spotlight:** `CoreSpotlight` framework. Re-index on save/update/delete.
- **Live Activities:** `ActivityKit`. Requires `NSSupportsLiveActivities` in Info.plist.

---

## UI Changes

- **New target:** `GhostNotesWatch` (watchOS app)
- **Settings:** "Widgets" section (configure widget content) + "Shortcuts" section (Siri setup guide)
- **Reading View:** Adds "Start Live Activity" button on iPhone when reading
- **macOS:** Spotlight integration already supported via CoreSpotlight (same API)

---

## Testing Plan

- [ ] Add small/medium widget to home screen → shows correct streak and article count
- [ ] Tap widget article → opens Ghost Notes to correct article
- [ ] "Save to Ghost Notes" Siri shortcut works from share sheet
- [ ] "What's on my reading list?" Siri returns correct count
- [ ] Watch app shows articles synced from iPhone
- [ ] Mark article as read on Watch → syncs back to iPhone app
- [ ] Spotlight search for article title → correct result appears
- [ ] Live Activity starts when reading → shows on Lock Screen

---

## Out of Scope for R13

- iPad widgets (can add in R14)
- watchOS standalone sync without iPhone nearby
- SiriKit voice override for reading articles aloud
- Live Activities on macOS (not supported)
