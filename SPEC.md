# GhostNotes — AI-Powered Read-Later App

## 1. Concept & Vision

GhostNotes is a minimalist read-later app that saves articles for offline reading and uses AI to surface what matters. It feels like a private library — calm, focused, and personal. The AI summarization turns long-form content into digestible insights, making it effortless to stay informed without doomscrolling.

**Tagline:** _Read less, understand more._

---

## 2. Design Language

### Aesthetic Direction
Inspired by Moleskine's ruled notebook meets a dark-mode terminal. Clean typographic hierarchy with generous whitespace and a restrained palette. No decorative clutter — content is king.

### Color Palette
| Role | Hex | Usage |
|---|---|---|
| Background | `#0D0D0D` | Main background |
| Surface | `#1A1A1A` | Cards, sheets |
| Surface Secondary | `#262626` | Input fields, dividers |
| Accent | `#8B5CF6` | Buttons, highlights (violet) |
| Accent Secondary | `#A78BFA` | Secondary actions |
| Text Primary | `#F5F5F5` | Headings, body |
| Text Secondary | `#A3A3A3` | Captions, metadata |
| Text Tertiary | `#525252` | Placeholders |
| Destructive | `#EF4444` | Delete, errors |
| Success | `#22C55E` | Completed, saved |

### Typography
- **Display:** SF Pro Display, 28pt bold — screen titles
- **Title:** SF Pro Display, 20pt semibold — article titles
- **Body:** SF Pro Text, 16pt regular — article content, summaries
- **Caption:** SF Pro Text, 13pt regular — metadata, timestamps
- **Monospace:** SF Mono, 14pt — URLs, technical content

### Spatial System
- Base unit: 4pt
- Card padding: 16pt
- Section spacing: 24pt
- Screen margins: 20pt
- Corner radius (cards): 12pt
- Corner radius (buttons): 8pt

### Motion Philosophy
- Transitions: 250ms ease-out
- Card press: scale 0.98, 150ms
- Sheet presentation: spring animation
- Skeleton loading shimmer: 1.5s infinite

---

## 3. Layout & Structure

### Screen Architecture
1. **LibraryView** (Tab 1) — List of saved articles with search
2. **AddArticleView** — Sheet to add URL
3. **ArticleDetailView** — Full article with AI summary
4. **SettingsView** (Tab 2) — App preferences

### Navigation
- `TabView` with two tabs: Library, Settings
- `NavigationStack` within each tab
- Modal sheet for adding articles

### Library Layout
- Search bar at top (sticky)
- Segmented control: All / Unread / Archived
- Vertical list of `ArticleCardView` items
- Pull-to-refresh for re-fetching article content
- Swipe actions: Archive (left), Delete (right)
- FAB-style "+" button to add articles

---

## 4. Features & Interactions

### Core Features

**F1: Save Article by URL**
- User taps "+" → AddArticleView sheet appears
- Paste or type URL → validates format
- App fetches metadata (title, favicon, description) via Open Graph
- Saves to local SQLite database
- Shows success toast on save

**F2: Offline Reading**
- Article content cached locally after first fetch
- Web page content extracted and cleaned (Readability-style)
- Images downloaded for offline access
- Offline indicator shown when no network

**F3: AI Summarization**
- Each article generates a 3-bullet summary
- Summary displayed prominently at top of ArticleDetailView
- Summaries stored locally; regeneratable via context menu
- Powered by a mock AI service (local generation for now)

**F4: Library Management**
- Filter: All, Unread, Archived
- Sort: Date Added (newest first)
- Search: filter by title or domain
- Swipe to archive (removes from main list)
- Swipe to delete (with confirmation)
- Long-press for context menu: Share, Archive, Delete, Regenerate Summary

**F5: Article Detail View**
- Hero: Article title, source favicon + domain, date saved
- AI Summary section (violet accent box)
- Full article content with clean typography
- Estimated reading time
- Scroll progress indicator
- Share button in toolbar

### States

**Article States:**
- `unread` — Default, appears in main list
- `read` — User scrolled past 80%
- `archived` — Moved to archive (hidden from main list)

**Empty States:**
- Library empty: Ghost icon + "Your library is empty" + "Save your first article" CTA
- No search results: "No articles match your search"
- Offline with no cache: "This article isn't available offline"

**Loading States:**
- Article card: shimmer skeleton
- Article detail: full-page skeleton
- AI summary: animated "Generating summary..." with dots

**Error States:**
- Invalid URL: inline red text under field
- Fetch failed: toast with retry option
- AI failed: "Summary unavailable" placeholder

---

## 5. Component Inventory

### ArticleCardView
- Container: Surface color, 12pt radius, 16pt padding
- Favicon (24x24) + domain name (caption, secondary)
- Title (title font, 2 lines max, truncate)
- Summary preview (body, 3 lines max, secondary color) — only if summary exists
- Estimated reading time badge
- Unread indicator: small violet dot
- States: default, pressed (scale 0.98), swiping

### AddArticleSheet
- Title: "Add Article" (display font)
- URL TextField with paste button
- "Save Article" primary button (full width, violet)
- "Cancel" text button
- States: empty, valid URL, invalid URL (inline error), saving (loading)

### AISummaryCard
- Container: violet tint (#8B5CF6 @ 10% opacity), 12pt radius
- Header: "✨ AI Summary" (title font)
- Bullet points (3 max), each < 280 chars
- "Regenerate" button (caption, accent color)
- States: loading (animated dots), loaded, unavailable

### SearchBar
- Background: surface secondary
- Magnifying glass icon
- Placeholder: "Search articles..."
- Clear button when text present
- Cancel button when focused

### SettingsView
- Section: "Appearance" — (future: theme toggle)
- Section: "Storage" — Clear cache button, storage used display
- Section: "About" — Version, GitHub link

---

## 6. Technical Approach

### Framework & Architecture
- **UI:** SwiftUI (iOS 26+)
- **Architecture:** MVVM
- **Database:** SQLite.swift (local persistence)
- **Networking:** URLSession (article fetching)
- **Content Extraction:** Basic HTML parsing (no external dependencies)

### Data Model

```swift
struct Article {
    let id: UUID
    let url: String
    let title: String
    let domain: String
    let faviconURL: String?
    let content: String?        // Extracted article content
    let summary: String?        // AI-generated summary (JSON array string)
    let estimatedReadingTime: Int  // minutes
    let dateAdded: Date
    var status: ArticleStatus   // unread, read, archived
}

enum ArticleStatus: String {
    case unread
    case read
    case archived
}
```

### ArticleStore Service
- Singleton `ArticleStore` (ObservableObject)
- CRUD operations against SQLite
- Methods: `addArticle(url:)`, `fetchArticle(id:)`, `updateStatus`, `deleteArticle`, `searchArticles`
- Uses Combine for reactive updates

### File Structure
```
ghost-notes-ios/
├── project.yml
├── App/
│   ├── GhostNotesApp.swift
│   └── ContentView.swift
├── Models/
│   └── Article.swift
├── Services/
│   └── ArticleStore.swift
├── Views/
│   ├── LibraryView.swift
│   ├── ArticleDetailView.swift
│   ├── ArticleCardView.swift
│   ├── AddArticleSheet.swift
│   ├── AISummaryCard.swift
│   └── SettingsView.swift
├── Utilities/
│   └── Theme.swift
└── Resources/
    └── Assets.xcassets/
```

### Dependencies
- **SQLite.swift** (SPM) — `https://github.com/stephencelis/SQLite.swift` — database

### Build Configuration
- Deployment Target: iOS 26.0
- Swift Version: 5.9
- Xcode: 15.0+
