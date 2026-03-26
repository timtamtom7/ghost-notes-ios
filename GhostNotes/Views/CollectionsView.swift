import SwiftUI

struct CollectionsView: View {
    @Bindable var viewModel: LibraryViewModel
    @State private var showingAddCollection = false
    @State private var newCollectionName = ""
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            if viewModel.collections.isEmpty {
                emptyState
            } else {
                collectionList
            }
        }
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddCollection = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .tint(.primary)
            }
        }
        .alert("New Collection", isPresented: $showingAddCollection) {
            TextField("Collection name", text: $newCollectionName)
            Button("Cancel", role: .cancel) {
                newCollectionName = ""
            }
            Button("Create") {
                Task {
                    await viewModel.addCollection(name: newCollectionName)
                    newCollectionName = ""
                }
            }
        } message: {
            Text("Enter a name for your new collection.")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 56))
                .foregroundColor(.ghost)
            
            Text("No collections yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Create collections to organize\nyour saved articles.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingAddCollection = true
            } label: {
                Label("Create a collection", systemImage: "plus")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.background)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primary)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .padding(32)
    }
    
    private var collectionList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.collections) { collection in
                    CollectionRow(
                        collection: collection,
                        articleCount: viewModel.articles.filter { $0.collectionName == collection.name }.count
                    )
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteCollection(collection) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

struct CollectionRow: View {
    let collection: Collection
    let articleCount: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(Color.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)

                Text("\(articleCount) article\(articleCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        CollectionsView(viewModel: LibraryViewModel())
    }
}
