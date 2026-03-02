import SwiftUI

struct UpdatesView: View {

//    @EnvironmentObject var viewModel: HomeBrewVM
    @Environment(HomeBrewVM.self) private var viewModel
    @State private var showingUpgradeAllConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar row
            HStack {
                if viewModel.outdatedPackages.isEmpty && !viewModel.isLoadingUpdates {
                    Text("Everything is up to date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(viewModel.outdatedPackages.count) update\(viewModel.outdatedPackages.count == 1 ? "" : "s") available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await viewModel.refreshOutdated() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
//                .disabled(viewModel.isLoadingUpdates || viewModel.isOperationInProgress)
                .disabled(viewModel.isLoadingUpdates)

                if !viewModel.outdatedPackages.isEmpty {
                    Button("Update All") {
                        showingUpgradeAllConfirm = true
                    }
                    .buttonStyle(.borderedProminent)
//                    .disabled(viewModel.isOperationInProgress)
                    .confirmationDialog(
                        "Update all packages?",
                        isPresented: $showingUpgradeAllConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Update All", role: .destructive) {
                            Task { await viewModel.upgradeAll() }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will run `brew upgrade` for all outdated formulae and casks.")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)

            Divider()

            if viewModel.isLoadingUpdates {
                LoadingView(message: "Checking for updates…")
            } else if viewModel.outdatedPackages.isEmpty {
                EmptyStateView(
                    systemImage: "checkmark.seal.fill",
                    title: "Up to Date",
                    message: "All installed packages are at their latest versions.",
                    accentColor: .green
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        // Apps section
                        if !viewModel.outdatedApps.isEmpty {
                            SectionHeader(title: "Apps", count: viewModel.outdatedApps.count)
                            ForEach(viewModel.outdatedApps) { package in
                                PackageCardView(package: package)
                                if package.id != viewModel.outdatedApps.last?.id {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }

                        // CLI Tools section
                        if !viewModel.outdatedTools.isEmpty {
                            SectionHeader(title: "CLI Tools", count: viewModel.outdatedTools.count)
                            ForEach(viewModel.outdatedTools) { package in
                                PackageCardView(package: package)
                                if package.id != viewModel.outdatedTools.last?.id {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Updates")
        .task {
            if viewModel.outdatedPackages.isEmpty && !viewModel.isLoadingUpdates {
                await viewModel.refreshOutdated()
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        Text("\(title) — \(count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }
}

#Preview {
    UpdatesView()
        .environment(HomeBrewVM())
}
