import SwiftUI

struct ContentView: View {
    @State private var viewModel = LibraryViewModel()
    
    var body: some View {
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
}

#Preview {
    ContentView()
}
