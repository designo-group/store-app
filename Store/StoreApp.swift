//
//  StoreApp.swift
//  Store
//
//  Created by Rodrigue de Guerre on 02/03/2026.
//

import SwiftUI

@main
struct InstoolApp: App {
    @State private var viewModel = HomeBrewVM()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Brew") {
                Button("Refresh Installed") {
                    Task { await viewModel.refreshInstalled() }
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Check for Updates") {
                    Task { await viewModel.refreshOutdated() }
                }
                .keyboardShortcut("u", modifiers: [.command, .shift])

                Divider()

                Button("Clear Activity Log") {
//                    viewModel.clearLog()
                }
            }
        }
    }
}
