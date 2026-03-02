//
//  BrewManager.swift
//  Manager
//
//  Created by Rodrigue de Guerre on 02/12/2025.
//
import Foundation
import SwiftUI


enum LogLevel: String, CaseIterable, Sendable {
    case info
    case success
    case warning
    case error

    var systemImage: String {
        switch self {
        case .info:    return "info.circle"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .info:    return .secondary
        case .success: return .green
        case .warning: return .orange
        case .error:   return .red
        }
    }

    var prefix: String {
        switch self {
        case .info:    return ""
        case .success: return "✓ "
        case .warning: return "⚠ "
        case .error:   return "✗ "
        }
    }
}


struct LogEntry: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let message: String
    let level: LogLevel

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    init(message: String, level: LogLevel = .info) {
        self.id = UUID()
        self.timestamp = Date()
        self.message = message
        self.level = level
    }
}
