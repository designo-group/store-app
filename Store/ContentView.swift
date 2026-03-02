//
//  ContentView.swift
//  Store
//
//  Created by Rodrigue de Guerre on 02/03/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(HomeBrewVM.self) private var viewModel
    
    var body: some View {
        Group {
            if viewModel.isStartingUp {
                BrewSplashScreenView(phase: .startingUp)
            } else if viewModel.isLoading {
                BrewSplashScreenView(phase: .loadingData)
            } else if viewModel.isShellStarting {
                BrewSplashScreenView(phase: .startingShell)
            } else {
                NavigationSplitView {
                    SidebarView()
                } detail: {
                    switch viewModel.selectedSection {
                    case .discover: DiscoverView()
                    case .installed: InstalledView()
                    case .updates: UpdatesView()
                    case .activityLog: ActivityLogView()
                    }
                }
                .overlay(alignment: .bottom) {
                    if let toast = viewModel.toast {
                        ToastView(item: toast)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 24)
                            .zIndex(999)
                    }
                }
                .animation(.spring(duration: 0.35), value: viewModel.toast)
            }
        }
        .task {
            viewModel.startShell()
            if viewModel.installedPackages.isEmpty {
                let brew = await viewModel.checkForExistingBrew()
                if brew == true {
                    await viewModel.updateBrew()
                } else {
                    await viewModel.installBrew()
                }
                await viewModel.startBrew()
                await viewModel.fetchAllPackages()
            }
        }
        .sheet(isPresented: Binding(get: { viewModel.isAwaitingPassword },
                                   set: { viewModel.isAwaitingPassword = $0 })) {
            PasswordPromptView()
        }
    }
}

#Preview {
    ContentView()
        .environment(HomeBrewVM())
}
