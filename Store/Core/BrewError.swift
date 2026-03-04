//
//  BrewError.swift
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
