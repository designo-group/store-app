//
//  BrewManager.swift
//  Manager
//
//  Created by Rodrigue de Guerre on 02/12/2025.
//
import Foundation


enum PackageType: String, Codable, CaseIterable, Hashable {
    case formula
    case cask

    var displayName: String {
        switch self {
        case .formula: return "CLI Tool"
        case .cask: return "App"
        }
    }

    var pluralName: String {
        switch self {
        case .formula: return "CLI Tools"
        case .cask: return "Apps"
        }
    }

    var systemImage: String {
        switch self {
        case .formula: return "terminal.fill"
        case .cask: return "app.fill"
        }
    }
}


struct Package: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var type: PackageType
    var description: String
    var installedVersion: String?
    var latestVersion: String
    var homepage: String
    var isOutdated: Bool
    var isFavorite: Bool
    var dependencies: [String]
    var caveats: String?
    
    var imgURL: URL?

    var isInstalled: Bool { installedVersion != nil }

    var displayVersion: String {
        if let installed = installedVersion {
            return installed
        }
        return latestVersion.isEmpty ? "unknown" : latestVersion
    }

    init(
        id: String,
        name: String,
        type: PackageType,
        description: String = "",
        installedVersion: String? = nil,
        latestVersion: String = "",
        homepage: String = "",
        isOutdated: Bool = false,
        isFavorite: Bool = false,
        dependencies: [String] = [],
        caveats: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.installedVersion = installedVersion
        self.latestVersion = latestVersion
        self.homepage = homepage
        self.isOutdated = isOutdated
        self.isFavorite = isFavorite
        self.dependencies = dependencies
        self.caveats = caveats
    }

    static func == (lhs: Package, rhs: Package) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
    }
}


struct BrewInfoResponse: Decodable {
    let formulae: [BrewFormula]
    let casks: [BrewCask]
}

struct BrewFormula: Decodable {
    let name: String
    let fullName: String?
    let desc: String?
    let homepage: String
    let versions: FormulaVersions
    let installed: [InstalledVersion]
    let dependencies: [String]
    let caveats: String?
    let outdated: Bool

    struct FormulaVersions: Decodable {
        let stable: String?
    }

    struct InstalledVersion: Decodable {
        let version: String
    }

    enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case desc
        case homepage
        case versions
        case installed
        case dependencies
        case caveats
        case outdated
    }
}

struct BrewCask: Decodable {
    let token: String
    let name: [String]
    let desc: String?
    let homepage: String
    let version: String
    let installed: String?
    let caveats: String?
    let outdated: Bool

    var displayName: String {
        name.first ?? token
    }
}

struct BrewOutdatedResponse: Decodable {
    let formulae: [OutdatedFormula]
    let casks: [OutdatedCask]

    struct OutdatedFormula: Decodable {
        let name: String
        let installedVersions: [String]
        let currentVersion: String

        enum CodingKeys: String, CodingKey {
            case name
            case installedVersions = "installed_versions"
            case currentVersion = "current_version"
        }
    }

    /// In `brew outdated --json=v2`, cask `installed_versions` is a plain String,
    /// whereas formula `installed_versions` is an Array<String>. This decoder
    /// handles both so the model stays unified.
    struct OutdatedCask: Decodable {
        let name: String
        let installedVersions: [String]
        let currentVersion: String

        enum CodingKeys: String, CodingKey {
            case name
            case installedVersions = "installed_versions"
            case currentVersion = "current_version"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = try c.decode(String.self, forKey: .name)
            currentVersion = try c.decode(String.self, forKey: .currentVersion)
            // v2 encodes cask installed_versions as a String; formulae use [String].
            if let array = try? c.decode([String].self, forKey: .installedVersions) {
                installedVersions = array
            } else if let single = try? c.decode(String.self, forKey: .installedVersions) {
                installedVersions = [single]
            } else {
                installedVersions = []
            }
        }

    }
}

extension Package {
    init(from formula: BrewFormula) {
        self.init(
            id: formula.name,
            name: formula.name,
            type: .formula,
            description: formula.desc ?? "",
            installedVersion: formula.installed.first?.version,
            latestVersion: formula.versions.stable ?? "",
            homepage: formula.homepage,
            isOutdated: formula.outdated,
            dependencies: formula.dependencies,
            caveats: formula.caveats
        )
    }

    init(from cask: BrewCask) {
        self.init(
            id: cask.token,
            name: cask.displayName,
            type: .cask,
            description: cask.desc ?? "",
            installedVersion: cask.installed,
            latestVersion: cask.version,
            homepage: cask.homepage,
            isOutdated: cask.outdated,
            caveats: cask.caveats
        )
    }
}
