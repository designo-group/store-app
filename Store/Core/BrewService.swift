//
//  BrewManager.swift
//  Store
//
//  Created by Rodrigue de Guerre on 02/12/2025.
//
import Foundation

enum BrewError: LocalizedError {
    case notInstalled
    case shellNotRunning
    case commandFailed(exitCode: Int32, output: String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Homebrew is not installed. Visit brew.sh to install it."
        case .shellNotRunning:
            return "The brew shell session is not running. Retrying…"
        case .commandFailed(let code, let output):
            let snippet = output.isEmpty ? "No output" : String(output.suffix(300))
            return "brew exited with code \(code): \(snippet)"
        case .parseError(let detail):
            return "Failed to parse Homebrew output: \(detail)"
        }
    }
}

/// Two-tier command execution:
///
/// READ commands (fetch, search, info, outdated) use `Process` with
/// separate stdout/stderr pipes. This is reliable, cancellable, and
/// immune to PTY timing issues. Homebrew's JSON always arrives cleanly
/// on stdout; auto-update noise on stderr is silently drained.
///
/// WRITE commands (install, uninstall, upgrade) use a persistent PTY
/// shell. A PTY is required because some cask installers call `sudo`
/// internally; `sudo` uses `isatty()` to decide whether to prompt for
/// a password. A plain Pipe fails that check — a PTY passes it.
final class BrewService {

    static let shared = BrewService()

    private(set) var executablePath: String?
    var isInstalled: Bool { executablePath != nil }


    private var pty: PTY?
    private(set) var isShellRunning = false
    private let sentinel = "__BREW_DONE__"

    /// Called on the main thread when brew / sudo asks for a password.
    var onPasswordRequired: (() -> Void)?

    private init() {
        executablePath = Self.detectBrew()
    }

    private static func detectBrew() -> String? {
        ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"].first {
            FileManager.default.isExecutableFile(atPath: $0)
        }
    }


    // MARK: - READ Commands
    func fetchInstalled() async throws -> [Package] {
        // Concurrent: each spawns its own Process.
        async let formulae = fetchInstalledFormulae()
        async let casks    = fetchInstalledCasks()
        let (f, c) = try await (formulae, casks)
        return f + c
    }

    private func fetchInstalledFormulae() async throws -> [Package] {
//        let json = try await captureStdout(["info", "--json=v2", "--installed"])
//        return try decodeInfo(json).formulae.map { Package(from: $0) }
        return []
    }

    private func fetchInstalledCasks() async throws -> [Package] {
//        let json = try await captureStdout(["info", "--json=v2", "--installed", "--cask"])
//        return try decodeInfo(json).casks.map { Package(from: $0) }
        return []
    }

    func fetchOutdated() async throws -> [Package] {
//        let json = try await captureStdout(["outdated", "--json=v2"])
//        guard let data = json.data(using: .utf8) else {
//            throw BrewError.parseError("Invalid UTF-8 from brew outdated")
//        }
//        let response: BrewOutdatedResponse
//        do { response = try JSONDecoder().decode(BrewOutdatedResponse.self, from: data) }
//        catch { throw BrewError.parseError(error.localizedDescription) }
//
//        return response.formulae.map {
//            Package(id: $0.name, name: $0.name, type: .formula,
//                    installedVersion: $0.installedVersions.first,
//                    latestVersion: $0.currentVersion, isOutdated: true)
//        } + response.casks.map {
//            Package(id: $0.name, name: $0.name, type: .cask,
//                    installedVersion: $0.installedVersions.first,
//                    latestVersion: $0.currentVersion, isOutdated: true)
//        }
        return []
    }

    func search(query: String) async throws -> [Package] {
        return []
    }

    func fetchInfo(names: [String], type: PackageType) async throws -> [Package] {
//        guard !names.isEmpty else { return [] }
//        var args = ["info", "--json=v2"]
//        if type == .cask { args.append("--cask") }
//        args.append(contentsOf: names)
//        let json    = try await captureStdout(args)
//        let decoded = try decodeInfo(json)
//        switch type {
//        case .formula: return decoded.formulae.map { Package(from: $0) }
//        case .cask:    return decoded.casks.map    { Package(from: $0) }
//        }
        return []
    }

    // MARK: - WRITE Commands
    func install(
        _ package: Package,
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws {
        var args = ["install"]
        if package.type == .cask { args.append("--cask") }
        args.append(package.id)
    }

    func uninstall(
        _ package: Package,
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws {
        var args = ["uninstall"]
        if package.type == .cask { args.append("--cask --force") }
        args.append(package.id)
    }

    func upgrade(
        _ package: Package,
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws {
        var args = ["upgrade"]
        if package.type == .cask { args.append("--cask") }
        args.append(package.id)
    }

    func upgradeAll(onOutput: @escaping @Sendable (String) -> Void) async throws {
    }
    
    //
    // MARK: - PTY
    //
    private var commandBuffer = ""
    private var isWaitingForCommand = false
    private var output: String = ""
    
    func sendInput(_ text: String) {
        guard let master = pty?.masterFileHandle else { return }
        if let data = text.data(using: .utf8) {
            master.write(data)
        }
    }
    
    func runCommand(_ cmd: String) async -> String {
        output = ""
        sendInput(cmd + "\n")
        return await waitForCommandToFinish()
    }
    
    func waitForCommandToFinish() async -> String {
        return await withCheckedContinuation { continuation in

            var didFinish = false

            DispatchQueue.main.async {
                self.commandBuffer = ""
            }

            pty?.masterFileHandle.readabilityHandler = { [weak self] handle in
                guard let self = self else { return }
                if didFinish { return }

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
                            let cleaned = trimmed
                                .replacingOccurrences(of: "__END_OF_COMMAND__", with: "")

                            // Clear buffer to prevent leftover triggers
                            self.commandBuffer = ""

                            // Restore main listener
                            self.listenForPTYOutput()

                            continuation.resume(returning: cleaned)
                        }
                    }
                }
            }
        }
    }

    // Continuation to resume async call
    private var commandFinishedContinuation: ((String) -> Void)?

    private func listenForPTYOutput() {
        guard let master = pty?.masterFileHandle else { return }

        // Non-blocking async reading using FileHandle's handler
        master.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }
            
            let data = handle.availableData
            if data.count > 0, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
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
            // Found a shell password prompt!
//            self.isAwaitingPassword = true
        }
    }
    
    func cleanPTYOutput(_ text: String) -> String {
        // Remove ANSI escape sequences
        let ansiPattern = #"\u{001B}\[[0-9;]*[a-zA-Z]"#
        let cleaned = text.replacingOccurrences(of: ansiPattern, with: "", options: .regularExpression)

        // Trim whitespace + newlines
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - PTY Shell Lifecycle

    /// Starts the persistent PTY shell. Safe to call multiple times; stops any
    /// existing session first. The shell is used ONLY for mutation commands.
    func startShell() async {
        guard let brewPath = executablePath else { return }
        stopShell()

        let brewDir     = (brewPath as NSString).deletingLastPathComponent
        let inheritPath = ProcessInfo.processInfo.environment["PATH"] ?? ""

        let env: [String: String] = [
            "TERM":                    "dumb",
            "LC_ALL":                  "en_US.UTF-8",
            "LANG":                    "en_US.UTF-8",
            "PS1":                     "\(sentinel)\n",
            "PATH":                    "\(brewDir):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\(inheritPath)",
            "HOME":                    NSHomeDirectory(),
            "HOMEBREW_NO_AUTO_UPDATE": "1",
            "HOMEBREW_NO_ENV_HINTS":   "1",
            "HOMEBREW_NO_COLOR":       "1",
            "HOMEBREW_NO_ANALYTICS":   "1",
        ]

        let p = PTY(
            path: "/bin/zsh",
            args: ["--no-rcs", "--no-global-rcs", "-i"],
            envDict: env
        )
        
        p.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isShellRunning = false
                self?.pty = nil
            }
        }
        p.launch()
        pty = p
        isShellRunning = true

        // Let zsh write its first prompt.
        try? await Task.sleep(for: .milliseconds(400))

        // Disable TTY echo so commands we send don't appear in output.
//        sendRaw("stty -echo\n")
        try? await Task.sleep(for: .milliseconds(150))

        // Drain all startup output (initial prompts, stty confirmation, etc.)
//        await drainOutput(for: .milliseconds(500))
    }

    func submitPassword(_ password: String) {
//        sendRaw(password + "\n")
    }

    func stopShell() {
        pty?.terminationHandler = nil
        pty?.masterFileHandle.readabilityHandler = nil
        pty?.masterFileHandle.closeFile()
        pty = nil
    }

}
