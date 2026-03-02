import SwiftUI

struct ToastView: View {

    let item: ToastItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(item.isError ? .red : .green)
                .font(.system(size: 16, weight: .semibold))

            Text(item.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        ToastView(item: ToastItem(message: "wget installed", isError: false))
        ToastView(item: ToastItem(message: "Failed to install wget", isError: true))
    }
    .padding()
}
