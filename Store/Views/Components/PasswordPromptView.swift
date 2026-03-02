import SwiftUI

/// Shown as a sheet when brew (via sudo) asks for a password.
/// The entered password is forwarded directly to the PTY's stdin.
struct PasswordPromptView: View {
    @Environment(HomeBrewVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var password: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)

                Text("Password Required")
                    .font(.title3.weight(.semibold))

                Text("Homebrew needs your macOS password to complete this operation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .frame(maxWidth: 280)
                .onSubmit { submit() }

            HStack(spacing: 12) {
                Button("Cancel") {
                    // Send Ctrl-C to abort the waiting sudo prompt.
                    viewModel.submitPassword("\u{03}")
                    viewModel.isAwaitingPassword = false
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("OK") { submit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(password.isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(32)
        .frame(width: 400)
//        .background(Color.white)
//        .cornerRadius(12)
        .onAppear { isFocused = true }
    }

    private func submit() {
        guard !password.isEmpty else { return }
        viewModel.submitPassword(password)
        password = ""
        dismiss()
    }
}

#Preview {
    PasswordPromptView()
        .environment(HomeBrewVM())
}
