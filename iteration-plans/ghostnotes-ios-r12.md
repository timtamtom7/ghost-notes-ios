# Ghost Notes — R12: Social Features & Community

## Theme
"Reading is better together." R12 adds a social layer — shared libraries, collaborative annotation, reading circles, and a community feed for sharing highlights and insights.

---

## Feature Breakdown

### 1. Shared Libraries
**Goal:** Share article collections with friends, family, or a team

- [ ] `GhostNotesR12Service.SharedLibrary` model already defined
- [ ] Create shared library UI (name, public/private toggle, article picker)
- [ ] Add/remove articles from shared library
- [ ] Invite collaborators via link or username
- [ ] Shared library appears in recipient's "Collections" tab
- [ ] Real-time sync via CloudKit (or iCloud container)
- [ ] Library activity feed: "Tommaso added 3 articles"

### 2. Reading Circles
**Goal:** A small group reads the same article together and discusses

- [ ] `GhostNotesR12Service.ReadingCircle` model already defined
- [ ] Create reading circle: name, description, initial article
- [ ] Join via invite link
- [ ] Circle home: shows current article, member list, activity
- [ ] Current book display with progress (who's reading what)
- [ ] Leave circle / dissolve circle
- [ ] Reading circle widget for home screen

### 3. Community Feed
**Goal:** A public (opt-in) feed of shared highlights and reading insights

- [ ] `GhostNotesR12Service.CommunityPost` model already defined
- [ ] Post creation: text + optional article link + optional highlight
- [ ] Post display: author (anonymous or display name), content, reactions
- [ ] Reactions: 👍 ❤️ 💡 🔖 (toggle on/off)
- [ ] Comment thread (flat, no nesting)
- [ ] Privacy: posts anonymized by default (`anonymizeBeforeSharing: true`)
- [ ] Community tab in main nav
- [ ] Infinite scroll feed

### 4. Collaborative Annotation
**Goal:** Annotate any article collaboratively with circle members

- [ ] `GhostNotesR12Service.CollaborativeAnnotation` model already defined
- [ ] Add annotation at a specific position in an article
- [ ] Annotations appear as colored markers in the reading view
- [ ] Click marker → annotation card with text + replies
- [ ] Reply to annotation (flat replies)
- [ ] Anonymous vs. named annotations (controlled by privacy settings)
- [ ] Annotations sync per article via CloudKit

### 5. Privacy Controls
**Goal:** User has full control over what they share

- [ ] `GhostNotesR12Service.PrivacySettings` already defined
- [ ] Settings UI for all privacy options:
  - Anonymize before sharing (on/off)
  - Default post visibility (Public / Community Only / Private)
  - Share reading activity (on/off — for circles)
  - Allow collaborative annotation on your articles (on/off)
- [ ] Privacy dashboard: shows what other users see of your profile

---

## Technical Approach

- **Sync:** CloudKit private database for per-user data; shared database for shared libraries and circles
- **Community feed:** Pull-to-refresh + pagination via CloudKit query
- **Real-time:** CloudKit subscriptions for push notifications on new posts/annotations
- **Privacy:** All social data stays within CloudKit; no third-party social APIs

---

## UI Changes

- **New tab:** "Community" (between Highlights and Settings) — or as a sub-section in For You
- **Shared Library sheet:** article picker + collaborator management
- **Reading Circle sheet:** member avatars, current article card, activity feed
- **Annotation markers:** colored dots in reading view gutter
- **Post composer:** bottom sheet with text field, optional article/highlight attachment
- **Settings → Privacy:** new section with toggles

---

## Testing Plan

- [ ] Create shared library → share link → recipient sees library and articles
- [ ] Create reading circle → invite friend → both see same circle home
- [ ] Post a highlight with article link → appears in community feed
- [ ] Add annotation to article → annotation marker appears at correct position
- [ ] Toggle privacy off → profile no longer shows in community
- [ ] Anonymous post → shows "Anonymous Reader" not real name

---

## Out of Scope for R12

- Direct messaging between users
- Social graph discovery (finding friends)
- Monetization of community features (R13 subscription tier covers this)
- Rich text in community posts
