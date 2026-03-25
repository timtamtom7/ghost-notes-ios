# Ghost Notes — iOS Product Spec

## Concept & Vision
Ghost Notes is a focused read-it-later app for iOS. Save articles, read them distraction-free, let AI surface what matters. The experience feels like a private reading room — calm, intentional, no noise. Articles you save here are respected; they're not just bookmarks, they're commitments.

## Design Language

### Aesthetic Direction
"Quiet library at midnight." Dark surfaces, warm paper-toned reading views, ghost-like subtle animations. The app breathes — nothing is rushed or loud.

### Color Palette
| Role | Hex |
|------|-----|
| Background | #0A0A0F |
| Surface | #16161F |
| Surface Elevated | #1E1E2A |
| Primary | #7B6CF6 |
| Accent | #F0E6FF |
| Text Primary | #F5F5F7 |
| Text Secondary | #8E8E93 |
| Text Tertiary | #48484A |
| Separator | #2C2C34 |
| Ghost | #3D3D50 |
| Success | #34C759 |
| Error | #FF453A |

### Typography
- Display: SF Pro Display Bold, 34pt
- Title: SF Pro Display Semibold, 24pt
- Heading: SF Pro Text Semibold, 20pt
- Body: SF Pro Text Regular, 17pt
- Caption: SF Pro Text Regular, 13pt
- Reading body: New York, 18pt, line-height 1.6

### Spacing
8pt grid. xxs=4, xs=8, sm=12, md=16, lg=24, xl=32, xxl=48

### Motion
- Card appear: 200ms spring(0.7)
- Screen transition: 350ms easeInOut
- Sheet present: 400ms spring(0.8)
- Reading progress: 100ms linear
- Breathing orb: 4000ms easeInOut repeating (for loading states)

## Core Features

### R1 — Foundation
- URL input field to save articles
- Basic article metadata display (title, domain, description)
- Article list view (library)
- Delete/archive articles
- Local SQLite storage

### R2 — Core Workflow
- AI summarization of articles (on-device using NaturalLanguage)
- Named collections/lists (Deep Dives, Research, etc.)
- Article reading mode (distraction-free)
- Estimated reading time
- Mark as read

### R3 — Advanced
- Search across all saves
- Reading progress tracking
- Stats page (saved, read, culled counts)
- Font size controls in reading mode
- Reading history

### R4 — Polish & Platform
- Share extension (save from Safari/other apps)
- iPad layout (NavigationSplitView)
- Offline reading mode
- Light/dark reading themes

### R5 — Offline Reading & Share Extension Sync
- **Offline reading**: Full article body content is fetched and saved locally at save time, enabling distraction-free reading without network
- **Share extension sync**: Articles saved via share extension are automatically imported into the main app via App Group storage
- Article deduplication in share extension (by URL)
- Reading time auto-calculated from body word count
- Real article titles/descriptions extracted from page metadata

### R6 — Polish, Stability & Depth
- Fix reported crashes and edge cases
- URL deduplication across save methods
- Empty state improvements throughout
- Build stability (warnings resolved, clean builds)

## Architecture
MVVM + Services. SQLite.swift for persistence. NaturalLanguage for on-device AI summaries.

## Technical
- iOS 26, SwiftUI
- SQLite.swift
- NaturalLanguage framework (on-device AI)
- WidgetKit (future)
- Privacy manifest required
