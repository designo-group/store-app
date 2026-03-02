import SwiftUI

struct InstalledView: View {

//    @EnvironmentObject var viewModel: HomeBrewVM
    @Environment(HomeBrewVM.self) private var viewModel
    @State private var selectedTab: PackageType = .cask

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Type", selection: $selectedTab) {
                    Text("Apps (\(viewModel.installedApps.count))")
                        .tag(PackageType.cask)
                    Text("CLI Tools (\(viewModel.installedTools.count))")
                        .tag(PackageType.formula)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
                Spacer()
                Button {
                    Task { await viewModel.refreshInstalled() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isLoadingInstalled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)

            Divider()

            if viewModel.isLoadingInstalled {
                LoadingView(message: "Loading installed packages…")
            } else {
                let packages = selectedTab == .cask
                    ? viewModel.installedApps
                    : viewModel.installedTools

                if packages.isEmpty {
                    EmptyStateView(
                        systemImage: selectedTab == .cask ? "app" : "terminal",
                        title: "No \(selectedTab.pluralName) Installed",
                        message: "Packages you install will appear here."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(packages) { package in
                                PackageCardView(package: package)
                                if package.id != packages.last?.id {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Installed")
        .task {
            if viewModel.installedPackages.isEmpty {
                await viewModel.refreshInstalled()
            }
        }
    }
}

#Preview {
    InstalledView()
        .environment(HomeBrewVM())
}
