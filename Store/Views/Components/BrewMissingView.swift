import SwiftUI

struct BrewMissingView: View {

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "mug.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.brown.opacity(0.6))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text("Homebrew Not Found")
                    .font(.title2.weight(.semibold))

                Text("Støre requires Homebrew to be installed.\nVisit brew.sh to install it, then relaunch the app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            HStack(spacing: 12) {
                Button("Open brew.sh") {
                    NSWorkspace.shared.open(URL(string: "https://brew.sh")!)
                }
                .buttonStyle(.borderedProminent)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    BrewMissingView()
        .frame(width: 600, height: 400)
}
