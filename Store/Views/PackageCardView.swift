import SwiftUI

struct PackageCardView: View {

//    @EnvironmentObject var viewModel: HomeBrewVM
    @Environment(HomeBrewVM.self) private var viewModel
    let package: Package

    @State private var showingUninstallConfirm = false
    @State private var showingDetail = false
    @State private var isHovered = false

    private var isActivePackage: Bool {
//        viewModel.activeOperationPackageId == package.id
        false
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            PackageIconView(type: package.type, imgURL: package.imgURL, isInstalled: package.isInstalled)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(package.name)
                        .font(.headline)
                        .lineLimit(1)

                    // Type badge
                    Text(package.type.displayName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))

                    if package.isOutdated {
                        Text("UPDATE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()

                    // Favorite star
                    Button {
//                        viewModel.toggleFavorite(package)
                    } label: {
                        Image(systemName: package.isFavorite ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(package.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .opacity(isHovered || package.isFavorite ? 1 : 0)
                }

                if !package.description.isEmpty {
                    Text(package.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Version line
                HStack(spacing: 8) {
                    if let installed = package.installedVersion {
                        Label(installed, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    if package.isOutdated {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(package.latestVersion)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if !package.isInstalled && !package.latestVersion.isEmpty {
                        Label(package.latestVersion, systemImage: "tag")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 8)

            // Action buttons
            HStack(spacing: 8) {
                if isActivePackage {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 80)
                } else if package.isOutdated {
                    Button("Upgrade") {
                        Task { await viewModel.upgrade(package: package) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
//                    .disabled(viewModel.isOperationInProgress)

                    Button {
                        showingUninstallConfirm = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
//                    .disabled(viewModel.isOperationInProgress)

                } else if package.isInstalled {
                    Button {
                        showingUninstallConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
//                    .disabled(viewModel.isOperationInProgress)

                } else {
                    Button("Install") {
                        Task { await viewModel.install(package: package) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
//                    .disabled(viewModel.isOperationInProgress)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.6) : Color.clear)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture { showingDetail = true }
        .sheet(isPresented: $showingDetail) {
            PackageDetailSheet(package: package)
        }
        .confirmationDialog(
            "Uninstall \(package.name)?",
            isPresented: $showingUninstallConfirm,
            titleVisibility: .visible
        ) {
            Button("Uninstall", role: .destructive) {
                Task { await viewModel.uninstall(package: package) }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will run `brew uninstall \(package.id)`. This cannot be undone.")
        }
    }
}

// MARK: - Package Icon

private struct PackageIconView: View {
    let type: PackageType
    let imgURL: URL?
    let isInstalled: Bool
    
    @State private var shouldUseFallback = false

    var body: some View {
        ZStack {
            if let imgURL = imgURL, shouldUseFallback == false {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                AsyncImage(url: imgURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // Placeholder (App Icon)
                        Image(systemName: type.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 30, height: 30)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: type == .cask
                                ? [Color.blue.opacity(0.7), Color.indigo.opacity(0.7)]
                                : [Color.green.opacity(0.7), Color.teal.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: type.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .task(id: imgURL) {
            guard let url = imgURL else { return }
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                // Check for 404 (if using the &default=404 trick)
                if (response as? HTTPURLResponse)?.statusCode == 404 {
                    shouldUseFallback = true
                    return
                }
                shouldUseFallback = false
            } catch {
                shouldUseFallback = true
            }
        }
    }
}

// MARK: - Package Detail Sheet

private struct PackageDetailSheet: View {

//    @EnvironmentObject var viewModel: HomeBrewVM
    @Environment(HomeBrewVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    let package: Package

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 14) {
                PackageIconView(type: package.type, imgURL: package.imgURL, isInstalled: package.isInstalled)
                    .scaleEffect(1.4)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(package.name)
                        .font(.title2.weight(.semibold))
                    Text(package.type.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(20)
            .background(.bar)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Description
                    if !package.description.isEmpty {
                        DetailSection(title: "Description") {
                            Text(package.description)
                                .foregroundStyle(.primary)
                        }
                    }

                    // Versions
                    DetailSection(title: "Versions") {
                        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {
                            if let installed = package.installedVersion {
                                GridRow {
                                    Text("Installed").foregroundStyle(.secondary)
                                    Text(installed).fontDesign(.monospaced)
                                }
                            }
                            if !package.latestVersion.isEmpty {
                                GridRow {
                                    Text("Latest").foregroundStyle(.secondary)
                                    Text(package.latestVersion).fontDesign(.monospaced)
                                }
                            }
                        }
                    }

                    // Homepage
                    if !package.homepage.isEmpty {
                        DetailSection(title: "Homepage") {
                            if let url = URL(string: package.homepage) {
                                Link(package.homepage, destination: url)
                                    .lineLimit(1)
                            }
                        }
                    }

                    // Dependencies
                    if !package.dependencies.isEmpty {
                        DetailSection(title: "Dependencies") {
                            FlowLayout(spacing: 6) {
                                ForEach(package.dependencies, id: \.self) { dep in
                                    Text(dep)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }

                    // Caveats
                    if let caveats = package.caveats, !caveats.isEmpty {
                        DetailSection(title: "Caveats") {
                            Text(caveats)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(10)
                                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 480, height: 460)
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .kerning(0.5)
            content()
        }
    }
}

// MARK: - Flow Layout (simple horizontal wrapping)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
                maxX = max(maxX, x)
            }
            self.size = CGSize(width: maxX, height: y + lineHeight)
        }
    }
}

#Preview {
    PackageCardView(package: Package(
        id: "wget", name: "wget", type: .formula,
        description: "Internet file retriever",
        installedVersion: "1.21.3", latestVersion: "1.21.4",
        isOutdated: true
    ))
    .environment(HomeBrewVM())
    .frame(width: 600)
}
