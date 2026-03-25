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
