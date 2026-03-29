# Ghost Notes — R11: Browser Extension, Email Digest & Import Expansion

## Theme
"Never lose an article again." R11 extends Ghost Notes beyond the app — save from anywhere, import your existing reading lists, and stay on top of your queue with email digests.

---

## Feature Breakdown

### 1. Browser Extension (Safari + Chrome)
**Goal:** Save articles to Ghost Notes directly from the browser

- [ ] Native Safari Web Extension using `browser.runtime` APIs
- [ ] Chrome Extension (same codebase, manifest v3)
- [ ] Extension popup: shows saved confirmation, quick-add with URL
- [ ] Saves to shared App Group container (`group.com.tomalabs.ghostnotes`)
- [ ] Badge icon shows save status (empty → checkmark on save)
- [ ] Keyboard shortcut: ⌘+Shift+G to save current page
- [ ] Duplicate detection (by URL) in extension before saving
- [ ] Graceful handling when main app is not installed

### 2. Email Digest
**Goal:** Periodic recap of your reading queue delivered to your inbox

- [ ] `GhostNotesR11Service` already defines `DigestFrequency` (daily/weekly/monthly)
- [ ] Email template rendering (plain text + basic HTML version)
- [ ] Backend: CloudKit push or server-side email dispatch (or placeholder API)
- [ ] Digest content:
  - Top 5 unread articles (title, domain, excerpt)
  - "Still on your list" — articles >30 days old
  - Reading streak reminder
  - CTA to open Ghost Notes
- [ ] User-configurable digest frequency in Settings
- [ ] Preview digest in Settings before subscribing

### 3. Import Expansion
**Goal:** Bring your existing reading history from other platforms

- [ ] `GhostNotesR11Service.importFrom(source:)` already stubs the following:
  - **Pocket** — OAuth + Pocket API import
  - **Instapaper** — OAuth + Instapaper API import
  - **Safari Reading List** — iCloud key-value read (macOS)
  - **Pinboard** — Pinboard API import (read-only token)
- [ ] Import progress UI (spinner + count)
- [ ] Deduplication against existing library
- [ ] Import summary: "Imported X articles, skipped Y duplicates"
- [ ] Bulk tag assignment on import

### 4. Retention Automation
**Goal:** Help users maintain a clean, current reading queue

- [ ] Auto-archive articles older than 90 days (configurable)
- [ ] "Still reading?" nudge notification at 7 days
- [ ] Weekly cull reminder if unread count > 20
- [ ] `archiveOldArticles(olderThan:)` stub already exists

---

## Technical Approach

- **Browser Extension:** Swift Web Extension (SFSafariExtension / WKWebView-based) + TypeScript content scripts
- **App Group:** All extension saves go to `group.com.tomalabs.ghostnotes` UserDefaults (same as share extension)
- **Email:** `GhostNotesR11Service.generateDigestEmail()` already implemented; needs CloudKit subscription or API endpoint
- **Import:** Each source uses its OAuth/token API; falls back gracefully with clear error messages

---

## UI Changes

- **Settings view:** New "Digest" section + "Import" section
- **Import UI:** Sheet with source icons, OAuth connect buttons, progress view
- **Empty state:** Contextual nudge to import from Pocket/Instapaper

---

## Testing Plan

- [ ] Save article from Safari extension → appears in iOS app within 5 seconds
- [ ] Import 100 Pocket articles → correct count + deduplication
- [ ] Email digest renders correctly in Apple Mail + Gmail
- [ ] Duplicate URL detection works across extension, share extension, and in-app save

---

## Out of Scope for R11

- Cloud sync of imported articles (future: R14)
- Two-way Pocket/Instapaper sync (read-only import)
- Browser extension for Firefox
