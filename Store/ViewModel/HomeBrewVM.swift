//
//  BrewManager.swift
//  Manager
//
//  Created by Rodrigue de Guerre on 02/12/2025.
//

import os
import Foundation
import Observation
import SwiftUI
internal import Combine

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case discover    = "Discover"
    case installed   = "Installed"
    case updates     = "Updates"
    case activityLog = "Activity"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .discover:    return "magnifyingglass"
        case .installed:   return "checkmark.circle"
        case .updates:     return "arrow.triangle.2.circlepath"
        case .activityLog: return "terminal"
        }
    }
}

enum DiscoverFilter: String, CaseIterable, Identifiable {
    case all      = "All"
    case apps     = "Apps"
    case cliTools = "CLI Tools"

    var id: String { rawValue }
}

struct ToastItem: Equatable {
    let message: String
    let isError: Bool
}

//@MainActor
@Observable
class HomeBrewVM: ObservableObject {
    /// - Parameter State
    /*@Published*/ var isStartingUp: Bool = false
    /*@Published*/ var isShellStarting: Bool = false
    /*@Published*/ var isLoading: Bool = false
    /*@Published*/ var errorMessage: String?
    
    /*@Published*/ var selectedSection: SidebarSection = .discover
//    /*@Published*/ var pendingUpdateCount: Int = 0

    /// - Parameter Search
    /*@Published*/ var searchQuery: String = ""
    /*@Published*/ var searchResults: [Package] = []
    /*@Published*/ var isSearching: Bool = false
    /*@Published*/ var discoverFilter: DiscoverFilter = .all
    
    /// - Parameter HomeBrew
    /*@Published*/ var allPackages: [Package] = []
    var allCasks: [Package] { allPackages.filter { $0.type == .cask } }
    var allFormulae: [Package] { allPackages.filter { $0.type == .formula } }
    
    // Used to display all the available packages when the search query is empty
    var filteredPackages: [Package] {
        switch discoverFilter {
        case .all:      return allPackages
        case .apps:     return allCasks
        case .cliTools: return allFormulae
        }
    }
    // Used when we enter a search query
    var filteredSearchResults: [Package] {
        switch discoverFilter {
        case .all:      return searchResults
        case .apps:     return searchResults.filter { $0.type == .cask }
        case .cliTools: return searchResults.filter { $0.type == .formula }
        }
    }
    
    /*@Published*/ var installedPackages: [Package] = []
    /*@Published*/ var isLoadingInstalled: Bool = false
    /*@Published*/ var outdatedPackages: [Package] = []
    /*@Published*/ var isLoadingUpdates: Bool = false
    
    var installedApps:  [Package] { installedPackages.filter { $0.type == .cask } }
    var installedTools: [Package] { installedPackages.filter { $0.type == .formula } }
    var outdatedApps:   [Package] { outdatedPackages.filter { $0.type == .cask } }
    var outdatedTools:  [Package] { outdatedPackages.filter { $0.type == .formula } }

    
    /// - Parameter PTY Helpers
    /*@Published*/ var isAwaitingPassword: Bool = false // Controls the PasswordPromptView sheet
    private var pty: PTY?
    private var _PATH: String? = nil
    
//    let brew = BrewService.shared
    
    var logEntries: [LogEntry] = []
    
    
    func checkForExistingBrew() async -> Bool {
        isStartingUp = true
        sendInput(AC.sh.disable_zle)
        await sleep(1)
        sendInput(AC.sh.disable_cr_sp)
        await sleep(1)
        sendInput(AC.sh.disable_prct)
        await sleep(1)
        sendInput(AC.sh.define_endpoint)
        await sleep(1)
                        
        let raw = await runCommand(AC.sh.which_brew)
        let txt = cleanPTYOutput(raw)

        print("RAW:", raw)
        print("CLEAN:", txt)
        
        return txt == AC.sh.PATH // might be to restrictive
    }
    
    func startBrew() async {
        print("Starting brew shell…")
        isShellStarting = true
        await refreshInstalled()
        await refreshOutdated()
        isShellStarting = false
        print("Shell ready.")
    }
    
    func installBrew() async { // we will probably need to run this first then restart the pty with $PATH set
        let _ = await runCommand(AC.sh.download_brew)
        isStartingUp = false
    }
    
    func updateBrew() async {
        let _ = await runCommand(AC.sh.brew_update)
        isStartingUp = false
    }
    
    func fetchAllPackages() async {
        do {
            let (formulaData, _) = try await URLSession.shared.data(from: AC.formulaListUrl)
            let (casksData, _) = try await URLSession.shared.data(from: AC.caskListUrl)
            let decoder = JSONDecoder()
            let formulae = try decoder.decode([BrewFormula].self, from: formulaData)
            let casks = try decoder.decode([BrewCask].self, from: casksData)
            
            let packages = (formulae.map { Package(from: $0) } + casks.map { Package(from: $0) }).map { /*[weak self]*/ pkg in
                var p = pkg
                let homepageURL = URL(string: pkg.homepage)
                let hostname = homepageURL?.host?.lowercased()
                let cleanHostname = hostname?.hasPrefix("www.") == true ? String(hostname!.dropFirst(4)) : hostname
                p.imgURL = cleanHostname.flatMap { URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\($0)&default=404") }
                return p
            }
            
            allPackages = packages
            searchResults = packages
        } catch {
            print("Failed to load all packages: \(error.localizedDescription)")
        }
    }
    
    func performSearch() {

    }

    func refreshInstalled() async {
        isLoadingInstalled = true
        defer { isLoadingInstalled = false }
        do {
            var packages = try await fetchInstalled()
            packages = packages.map { /*[weak self]*/ pkg in
                var p = pkg
                //                p.isFavorite = self?.favoriteIds.contains(pkg.id) ?? false
                let homepageURL = URL(string: pkg.homepage)
                let hostname = homepageURL?.host?.lowercased()
                let cleanHostname = hostname?.hasPrefix("www.") == true ? String(hostname!.dropFirst(4)) : hostname
                p.imgURL = cleanHostname.flatMap { URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\($0)&default=404") }
                return p
            }
            installedPackages = packages
            if !installedPackages.isEmpty {
                showToast("Loaded installed packages")
            } else {
                showToast("Failed to load installed packages", isError: true)
            }
        } catch {
//            log("Failed to load installed packages: \(error.localizedDescription)", level: .error)
            print("Failed to load installed packages: \(error.localizedDescription)")
        }
    }
    
    private func fetchInstalled() async throws -> [Package] {
        let formulae = try await fetchInstalledFormulae()
        let casks = try await fetchInstalledCasks()
        return formulae + casks
    }
    
    private func fetchInstalledFormulae() async throws -> [Package] {
        let txt = await runCommand("brew info --json=v2 --installed --cask")
        return try decodeInfo(txt).formulae.map { Package(from: $0) }
    }

    private func fetchInstalledCasks() async throws -> [Package] {
        let txt = await runCommand("brew info --json=v2 --installed --cask")
        return try decodeInfo(txt).casks.map { Package(from: $0) }
    }
    
    private func decodeInfo(_ json: String) throws -> BrewInfoResponse {
        guard let data = json.data(using: .utf8) else {
            throw BrewError.parseError("Invalid UTF-8 in brew info response")
        }
        struct RawResponse: Decodable {
            var formulae: [BrewFormula] = []
            var casks:    [BrewCask]    = []
        }
        do {
            let raw = try JSONDecoder().decode(RawResponse.self, from: data)
            return BrewInfoResponse(formulae: raw.formulae, casks: raw.casks)
        } catch {
            throw BrewError.parseError(error.localizedDescription)
        }
    }

    func refreshOutdated() async {
        isLoadingUpdates = true
        defer { isLoadingUpdates = false }
        do {
            let txt = await runCommand("brew outdated --json=v2")
            let response: BrewOutdatedResponse
            do {
                guard let data = txt.data(using: .utf8) else {
                    throw NSError(domain: "InvalidStringEncoding", code: 1)
                }
                response = try JSONDecoder().decode(BrewOutdatedResponse.self, from: data)
            } catch {
                throw BrewError.parseError(error.localizedDescription)
            }

            outdatedPackages = response.formulae.map {
                Package(id: $0.name, name: $0.name, type: .formula,
                        installedVersion: $0.installedVersions.first,
                        latestVersion: $0.currentVersion, isOutdated: true)
            } + response.casks.map {
                Package(id: $0.name, name: $0.name, type: .cask,
                        installedVersion: $0.installedVersions.first,
                        latestVersion: $0.currentVersion, isOutdated: true)
            }
            updateDockBadge()
        } catch {
            print("Failed to load updates: \(error.localizedDescription)")
        }
    }


    func install(package: Package) async -> Bool {
        print("Installing \(package.name)…")
        commandBuffer = ""
        isWaitingForCommand = true
        if package.type == .cask {
            sendInput(AC.sh.install_cask(package.id))
//            sendInput(AC.sh.install_cask(package.id))
        } else {
            sendInput(AC.sh.install(package.id))
//            sendInput(AC.sh.install(package.id))
        }
        let res = await waitForInstall()
        if res {
            showToast("\(package.name) installed")
        } else {
            showToast("Failed to install \(package.name)", isError: true)
        }
        return res
    }
    
    func upgrade(package: Package) async {
        print("Upgrading \(package.name)…")
        defer {
            Task {
                await refreshOutdated()
            }
        }
//        commandBuffer = ""
//        isWaitingForCommand = true
        sendInput(AC.sh.upgrade(package.id))
        let res = await waitForUpgrade()
        if res {
            showToast("\(package.name) upgraded")
        } else {
            showToast("Failed to upgrade \(package.name)", isError: true)
        }
    }

    func uninstall(package: Package) async -> Bool {
        print("Uninstalling \(package.name)…")
        commandBuffer = ""
        isWaitingForCommand = true
        sendInput(AC.sh.uninstall(package.id))
//        sendInput(AC.sh.uninstall(package.id))
        let res = await waitForUninstall()
        if res {
            showToast("\(package.name) uninstalled")
        } else {
            showToast("Failed to uninstall \(package.name)", isError: true)
        }
        return res
    }

    func upgradeAll() async {
        showToast("Not available yet", isError: true)
    }

    //
    // MARK: - PTY
    //
    var commandBuffer = ""
    var isWaitingForCommand = false
    var output: String = "" // Terminal output buffer

    func runCommand(_ cmd: String) async -> String {
        output = ""
        sendInput(cmd + "\n")
        return await waitForCommandToFinish()
    }
    
    func sendInput(_ text: String) {
        guard let master = pty?.masterFileHandle else { return }
        if let data = text.data(using: .utf8) {
            master.write(data)
        }
    }
    
    func waitForCommand() async -> String {
        while isWaitingForCommand {
            try? await Task.sleep(nanoseconds: 60_000_000)
        }
        return commandBuffer
    }
    
    func waitForInstall() async -> Bool {
        while isWaitingForCommand {
            try? await Task.sleep(nanoseconds: 60_000_000) // 60ms
            // timeout after 2min
        }
        // @TODO work on a more robust patter recog
        if output.contains("Installing") || output.contains("successfully") || output.contains("Installed") {
            return true
        }
        if output.lowercased().contains("error") {
            return false
        }
        return true
    }
    
    func waitForUpgrade() async -> Bool {
        while isWaitingForCommand {
            try? await Task.sleep(nanoseconds: 60_000_000) // 60ms
            // timeout after 2min
        }
        // @TODO work on a more robust patter recog
        if output.contains("successfully") || output.contains("Upgraded") {
            return true
        }
        if output.lowercased().contains("error") {
            return false
        }
        return true
    }
    
    func waitForUninstall() async -> Bool {
        while isWaitingForCommand {
            try? await Task.sleep(nanoseconds: 60_000_000)
        }
        print(output)
        // @TODO work on a more robust patter recog
        if output.contains("Uninstalling") || output.contains("Uninstalled") {
            return true
        }
        if output.lowercased().contains("error") {
            return false
        }
        return true
    }
    
    func waitForCommandToFinish() async -> String {
        await withCheckedContinuation { continuation in
            nonisolated(unsafe) var didFinish = false
//            let didFinish = OSAllocatedUnfairLock(initialState: false)

            DispatchQueue.main.async {
                self.commandBuffer = ""
            }

            guard let pty = self.pty else {
                continuation.resume(returning: "")
                return
            }

            pty.masterFileHandle.readabilityHandler = { [weak self] handle in
                guard let self = self else {
                    if !didFinish {
                        didFinish = true
                        continuation.resume(returning: "")
                    }
                    return
                }
                if didFinish { return }
//            pty.masterFileHandle.readabilityHandler = { [weak self] handle in
//                guard let self = self else {
//                    didFinish.withLock { state in
//                        guard !state else { return }
//                        state = true
//                        continuation.resume(returning: "")
//                    }
//                    return
//                }
//                guard !didFinish.withLock({ $0 }) else { return }

                let data = handle.availableData
                if data.isEmpty { return }

                if let text = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.commandBuffer.append(text)

                        let trimmed = self.commandBuffer
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        if trimmed.hasSuffix("__END_OF_COMMAND__") {
                            didFinish = true
                            // STOP reading before restoring main handler
                            self.pty?.masterFileHandle.readabilityHandler = nil
                            // Clean output
                            let cleaned = trimmed.replacingOccurrences(of: "__END_OF_COMMAND__", with: "")
                            // Clear buffer to prevent leftover triggers
                            self.commandBuffer = ""
                            // Restore main listener
                            self.listenForPTYOutput()
                            
                            continuation.resume(returning: cleaned)
                        }
                    }
                }
            }

//            // Optional: timeout to prevent hanging indefinitely
//            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
//                if !didFinish {
//                    didFinish = true
//                    self.pty?.masterFileHandle.readabilityHandler = nil
//                    continuation.resume(returning: self.commandBuffer)
//                }
//            }
        }
    }

    // Continuation to resume async call
    private var commandFinishedContinuation: ((String) -> Void)?
    
    private func listenForPTYOutput() {
        guard let master = pty?.masterFileHandle else { return }

        master.readabilityHandler = { handle in
            // Extract the data on the background thread
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            
            // Send the text (which is Sendable) to the MainActor
            // We capture 'self' explicitly here, but since it's a Task,
            // Swift 6 requires we handle the isolation crossing.
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.output.append(text)
                self.checkForPasswordPrompt(in: text)
                
                if self.isWaitingForCommand {
                    self.commandBuffer.append(text)
                    
                    if self.commandBuffer.contains("__END_OF_COMMAND__") {
                        let cleaned = self.commandBuffer
                            .replacingOccurrences(of: "__END_OF_COMMAND__", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        self.isWaitingForCommand = false
                        self.commandFinishedContinuation?(cleaned)
                        self.commandFinishedContinuation = nil
                    }
                }
            }
        }
    }
    
    private func checkForPasswordPrompt(in newOutput: String) {
        let passwordTriggers = [
            "password:",
            "sudo password:",
            "keychain password",
            "passphrase for"
        ]
        
        let lowercasedOutput = newOutput.lowercased()
        
        if passwordTriggers.contains(where: lowercasedOutput.contains) {
            self.isAwaitingPassword = true
        }
    }
    
    func submitPassword(_ password: String) {
        // The shell expects the password followed by a newline (Enter key)
        let cmd = password + "\n"
        sendInput(cmd)

        DispatchQueue.main.async {
            self.isAwaitingPassword = false
        }
    }
    
    func cleanPTYOutput(_ text: String) -> String {
        // Remove ANSI escape sequences
        let ansiPattern = #"\u{001B}\[[0-9;]*[a-zA-Z]"#
        let cleaned = text.replacingOccurrences(of: ansiPattern, with: "", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
    func startShell() {
        let shell = "/bin/zsh"

        let p = PTY(
            path: shell,
//            args: ["-i"],
            args: ["--no-rcs", "--no-global-rcs", "-i"],
            envDict: [
            "TERM": "xterm-256color",
            "LC_ALL": "en_US.UTF-8",
            "LANG": "en_US.UTF-8",
            "PATH": "/opt/homebrew/bin:/opt/homebrew/sbin",
            "PS1": "__END_OF_COMMAND__\n"
        ])

        self.pty = p
        self.pty?.terminationHandler = { [weak self] proc in
            print("Shell exited with \(proc.terminationStatus)")
            DispatchQueue.main.async {
                self?.isAwaitingPassword = false
            }
        }

        p.launch()

        // Start reading terminal output
        listenForPTYOutput()
    }
    
    func stopShell() {
        pty?.terminationHandler = nil
        pty?.masterFileHandle.readabilityHandler = nil
        pty?.masterFileHandle.closeFile()
        pty = nil
    }

    
    // MARK: - UI Elements
    var toast: ToastItem?
    var pendingUpdateCount: Int { outdatedPackages.count }
    
    func showToast(_ message: String, isError: Bool = false) {
        toast = ToastItem(message: message, isError: isError)
        Task {
            try? await Task.sleep(for: .seconds(3))
            self.toast = nil
        }
    }
    private func updateDockBadge() {
        let count = pendingUpdateCount
        if count > 0 {
            NSApplication.shared.dockTile.badgeLabel = "\(count)"
        } else {
            NSApplication.shared.dockTile.badgeLabel = nil
        }
    }
}


extension HomeBrewVM {
//    func log(_ message: String, level: LogLevel = .info) {
//        let entry = LogEntry(message: message, level: level)
//        logEntries.append(entry)
//        if logEntries.count > 2000 {
//            logEntries.removeFirst(200)
//        }
//    }
//
//    func clearLog() {
//        logEntries.removeAll()
//    }
}
