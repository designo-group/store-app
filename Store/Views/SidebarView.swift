import SwiftUI

struct SidebarView: View {
//    @EnvironmentObject var viewModel: HomeBrewVM
    @Environment(HomeBrewVM.self) private var viewModel
    
    var body: some View {
        @Bindable var vm = viewModel
        List(SidebarSection.allCases, id: \.self, selection: $vm.selectedSection) { section in
            Label {
                HStack {
                    Text(section.rawValue)
                    Spacer()
                    if section == .updates, viewModel.pendingUpdateCount > 0 {
                        Text("\(viewModel.pendingUpdateCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor, in: Capsule())
                    }
                }
            } icon: {
                Image(systemName: section.systemImage)
            }
            .tag(section)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        .safeAreaInset(edge: .bottom) {
            SidebarFooterView()
        }
    }
}

private struct SidebarFooterView: View {

//    @EnvironmentObject var viewModel: HomeBrewVM
    @Environment(HomeBrewVM.self) private var viewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                Image(systemName: "mug.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Støre")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
//                if viewModel.isOperationInProgress {
//                    ProgressView()
//                        .controlSize(.mini)
//                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    SidebarView()
        .environment(HomeBrewVM())
}
