import SwiftUI

struct DiscoverView: View {
    @Environment(HomeBrewVM.self) private var viewModel
    
    var body: some View {
        @Bindable var vm = viewModel
        
        VStack(spacing: 0) {
            // Filter bar
            HStack {
                Picker("Filter", selection: $vm.discoverFilter) {
                    ForEach(DiscoverFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)

            Divider()

            // Results
            if viewModel.isSearching {
                LoadingView(message: "Searching…")
            } else if viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
//                EmptyStateView(
//                    systemImage: "magnifyingglass",
//                    title: "Search Homebrew",
//                    message: "Find formulae and casks from the entire Homebrew catalogue."
//                )
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.filteredPackages) { package in
                            PackageCardView(package: package)
                            if package.id != viewModel.filteredSearchResults.last?.id {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            } else if viewModel.filteredSearchResults.isEmpty {
                EmptyStateView(
                    systemImage: "questionmark.circle",
                    title: "No Results",
                    message: "No packages found for \"\(viewModel.searchQuery)\"."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.filteredSearchResults) { package in
                            PackageCardView(package: package)
                            if package.id != viewModel.filteredSearchResults.last?.id {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Discover")
        .searchable(
            text: Binding(
                get: { viewModel.searchQuery },
                set: { newVal in
                    viewModel.searchQuery = newVal
                    viewModel.performSearch()
                }
            ),
            placement: .toolbar,
            prompt: "Search packages…"
        )
    }
}

#Preview {
    DiscoverView()
        .environment(HomeBrewVM())
}
