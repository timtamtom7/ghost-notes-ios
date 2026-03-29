import SwiftUI

struct MacContentView: View {
    @State private var viewModel = MacLibraryViewModel()
    @State private var showingSettings = false
    @State private var showingAddURL = false
    @State private var urlToAdd = ""

    var body: some View {
        NavigationSplitView {
            MacLibraryView(viewModel: viewModel, showingAddURL: $showingAddURL, urlToAdd: $urlToAdd)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } content: {
            MacArticleListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            if let article = viewModel.selectedArticle {
                MacReaderView(article: article, viewModel: viewModel)
            } else {
                emptyDetailView
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
        .background(Color.macBackground)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.macTextSecondary)
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showingSettings) {
            MacSettingsView()
        }
        .sheet(isPresented: $showingAddURL) {
            addURLSheet
        }
    }

    private var emptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.macGhost)
            Text("Select an article to read")
                .font(.title3)
                .foregroundColor(.macTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.macBackground)
    }

    private var addURLSheet: some View {
        VStack(spacing: 20) {
            Text("Save Article")
                .font(.title2.bold())
                .foregroundColor(.macTextPrimary)

            TextField("https://example.com/article", text: $urlToAdd)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.macSurfaceElevated)
                .cornerRadius(MacTheme.cornerRadiusSmall)
                .foregroundColor(.macTextPrimary)

            HStack(spacing: 12) {
                Button("Cancel") {
                    urlToAdd = ""
                    showingAddURL = false
                }
                .buttonStyle(MacSecondaryButtonStyle())

                Button("Save") {
                    Task {
                        await viewModel.addArticle(url: urlToAdd)
                        urlToAdd = ""
                        showingAddURL = false
                    }
                }
                .buttonStyle(MacPrimaryButtonStyle())
                .disabled(urlToAdd.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color.macSurface)
    }
}

struct MacPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.macBackground)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.macPrimary)
            .clipShape(RoundedRectangle(cornerRadius: MacTheme.cornerRadiusSmall))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MacSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(.macPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.macSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: MacTheme.cornerRadiusSmall))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MacDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(.macError)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.macError.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: MacTheme.cornerRadiusSmall))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

#Preview {
    MacContentView()
}
