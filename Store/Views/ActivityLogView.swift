import SwiftUI

struct ActivityLogView: View {

//    @EnvironmentObject var viewModel: HomeBrewVM
    @Environment(HomeBrewVM.self) private var viewModel
    @State private var filterLevel: LogLevel? = nil
    @State private var autoScroll = true

    private var displayedEntries: [LogEntry] {
//        guard let level = filterLevel else { return viewModel.logEntries }
//        return viewModel.logEntries.filter { $0.level == level }
        return []
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Level filter
                Picker("Level", selection: $filterLevel) {
                    Text("All").tag(Optional<LogLevel>.none)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Label(level.rawValue.capitalized, systemImage: level.systemImage)
                            .tag(Optional(level))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 140)

                Toggle(isOn: $autoScroll) {
                    Label("Auto-scroll", systemImage: "arrow.down.to.line")
                        .labelStyle(.titleOnly)
                }
                .toggleStyle(.checkbox)
                .font(.caption)

                Spacer()

//                Text("\(viewModel.logEntries.count) entries")
//                    .font(.caption)
//                    .foregroundStyle(.secondary)

                Button {
//                    viewModel.clearLog()
                } label: {
                    Label("Clear", systemImage: "trash")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
//                .disabled(viewModel.logEntries.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            if viewModel.logEntries.isEmpty {
                EmptyStateView(
                    systemImage: "terminal",
                    title: "No Activity",
                    message: "Output from Homebrew operations will appear here."
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(displayedEntries) { entry in
                                LogEntryRow(entry: entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: viewModel.logEntries.count) { _, _ in
                        if autoScroll, let last = displayedEntries.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Activity Log")
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Log Entry Row

private struct LogEntryRow: View {

    let entry: LogEntry
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Timestamp
            Text(entry.formattedTimestamp)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .frame(width: 60, alignment: .trailing)

            // Level icon
            Image(systemName: entry.level.systemImage)
                .font(.caption)
                .foregroundStyle(entry.level.color)
                .frame(width: 14)

            // Message
            Text(entry.level.prefix + entry.message)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(entry.level == .info ? .primary : entry.level.color)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .background(isHovered ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    ActivityLogView()
        .environment(HomeBrewVM())
}
