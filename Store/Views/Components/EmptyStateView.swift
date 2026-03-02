import SwiftUI

struct EmptyStateView: View {

    let systemImage: String
    let title: String
    let message: String
    var accentColor: Color = .secondary

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(accentColor.opacity(0.6))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct LoadingView: View {

    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack {
        EmptyStateView(
            systemImage: "magnifyingglass",
            title: "No Results",
            message: "Try searching for something else."
        )
        EmptyStateView(
            systemImage: "checkmark.seal.fill",
            title: "Up to Date",
            message: "All packages are current.",
            accentColor: .green
        )
    }
}
