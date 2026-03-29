import SwiftUI

struct MacContentView: View {
    @State private var viewModel = MacLibraryViewModel()
    @State private var selectedSidebarItem: SidebarItem = .library
    @State private var selectedArticle: Article?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility, sidebar: {
            SidebarView(selectedItem: $selectedSidebarItem, viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        }, content: {
            detailView
        }, detail: {
            Text("Select an article or view from the sidebar")
                .foregroundColor(.textTertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        })
        .frame(minWidth: 900, minHeight: 600)
        .background(Color.background)
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSidebarItem {
        case .library:
            MacLibraryView(viewModel: viewModel, selectedArticle: $selectedArticle)
        case .forYou:
            MacForYouView(viewModel: viewModel, selectedArticle: $selectedArticle)
        case .collections:
            MacCollectionsView(viewModel: viewModel)
        case .highlights:
            MacHighlightsView(viewModel: viewModel)
        case .stats:
            MacStatsView(viewModel: viewModel)
        case .archive:
            MacArchiveView(viewModel: viewModel, selectedArticle: $selectedArticle)
        }
    }
}

// MARK: - Sidebar

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case library = "Library"
    case forYou = "For You"
    case collections = "Collections"
    case highlights = "Highlights"
    case stats = "Stats"
    case archive = "Archive"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .library: return "books.vertical"
        case .forYou: return "sparkles"
        case .collections: return "folder"
        case .highlights: return "highlighter"
        case .stats: return "chart.bar"
        case .archive: return "archivebox"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    let viewModel: MacLibraryViewModel

    var body: some View {
        List(SidebarItem.allCases, selection: $selectedItem) { item in
            Label(item.rawValue, systemImage: item.icon)
                .tag(item)
        }
        .listStyle(.sidebar)
        .navigationTitle("Ghost Notes")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.addArticleFromInput() }
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Article")
            }
        }
    }
}
