# Ghost Notes

A read-it-later app for iOS. Save articles, read them distraction-free, and let AI surface what matters. Built to feel like a private reading room.

## Concept

- Save from anywhere via share extension
- Distraction-free reader
- AI summaries and highlights
- Archive organisation

## Targets

- iOS
- GhostNotesShareExtension

## Stack

- SwiftUI
- SwiftData
- WidgetKit
- Share extension

## Structure

A well-factored target layout: `Models/`, `Views/`, `Services/`, `App/`, `Utilities/`, plus a dedicated `GhostNotesShareExtension/`. Key types: `AISummaryCard`, `AddArticleSheet`, `ArchiveView`, `ArticleCard`.

Version 1.0.

## Status

Apple-platform experiment built to explore what an AI coding agent could produce for a native app. Not actively maintained.

Xcode projects here were generated with XcodeGen (`project.yml`); open the `.xcodeproj` directly.
