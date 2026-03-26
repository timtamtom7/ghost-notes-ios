import SwiftUI

struct ContentView: View {
    @State private var viewModel = LibraryViewModel()
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
    }
    
    private var iPhoneLayout: some View {
        NavigationStack {
            ZStack {
                Color.background
                    .ignoresSafeArea()
                
                TabView(selection: $viewModel.selectedTab) {
                    LibraryView(viewModel: viewModel)
                        .tabItem {
                            Label("Library", systemImage: "books.vertical")
                        }
                        .tag(LibraryViewModel.Tab.library)
                    
                    ArchiveView(viewModel: viewModel)
                        .tabItem {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tag(LibraryViewModel.Tab.archive)
                    
                    CollectionsView(viewModel: viewModel)
                        .tabItem {
                            Label("Collections", systemImage: "folder")
                        }
                        .tag(LibraryViewModel.Tab.collections)
                    
                    HighlightsView(viewModel: viewModel)
                        .tabItem {
                            Label("Highlights", systemImage: "highlighter")
                        }
                        .tag(LibraryViewModel.Tab.highlights)
                    
                    CommunityView(viewModel: viewModel)
                        .tabItem {
                            Label("Community", systemImage: "person.3")
                        }
                        .tag(LibraryViewModel.Tab.community)
                }
                .tint(.accent)
            }
            .task {
                await viewModel.load()
            }
        }
    }
    
    private var iPadLayout: some View {
        NavigationSplitView {
            // Sidebar
            List {
                Section {
                    Label("Library", systemImage: "books.vertical")
                        .onTapGesture { viewModel.selectedTab = .library }
                        .listRowBackground(viewModel.selectedTab == .library ? Color.primary.opacity(0.15) : Color.clear)
                    
                    Label("Archive", systemImage: "archivebox")
                        .onTapGesture { viewModel.selectedTab = .archive }
                        .listRowBackground(viewModel.selectedTab == .archive ? Color.primary.opacity(0.15) : Color.clear)
                    
                    Label("Collections", systemImage: "folder")
                        .onTapGesture { viewModel.selectedTab = .collections }
                        .listRowBackground(viewModel.selectedTab == .collections ? Color.primary.opacity(0.15) : Color.clear)
                    
                    Label("Highlights", systemImage: "highlighter")
                        .onTapGesture { viewModel.selectedTab = .highlights }
                        .listRowBackground(viewModel.selectedTab == .highlights ? Color.primary.opacity(0.15) : Color.clear)
                    
                    Label("Community", systemImage: "person.3")
                        .onTapGesture { viewModel.selectedTab = .community }
                        .listRowBackground(viewModel.selectedTab == .community ? Color.primary.opacity(0.15) : Color.clear)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Ghost Notes")
        } detail: {
            switch viewModel.selectedTab {
            case .library:
                LibraryView(viewModel: viewModel)
            case .archive:
                ArchiveView(viewModel: viewModel)
            case .collections:
                CollectionsView(viewModel: viewModel)
            case .highlights:
                HighlightsView(viewModel: viewModel)
            case .community:
                CommunityView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

#Preview {
    ContentView()
}
