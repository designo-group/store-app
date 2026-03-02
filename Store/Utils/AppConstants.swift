//
//  AppConstants.swift
//  Manager
//
//  Created by Rodrigue de Guerre on 03/12/2025.
//

import Foundation

typealias AC = AppConstants

public class AppConstants {
    
    // Never instantiate this class.
    private init() {}
    
    public static let legalTermsUrl = URL(string: "https://designø.com/legal/")!
    public static let appStoreUrl = URL(string: "https://itunes.apple.com/uk/app/id")!
    public static let brewDownloadUrl = URL(string: "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")!
    
    
    public static let faviconUrl = URL(string: "https://www.google.com/s2/favicons?sz=64&domain=")!
    public static let formulaListUrl = URL(string: "https://formulae.brew.sh/api/formula.json")!
    public static let caskListUrl = URL(string: "https://formulae.brew.sh/api/cask.json")!
    
    public static let sh = ShellCommands()
}


public class ShellCommands {
    public let PATH = "/opt/homebrew/bin/brew"
    
    public let download_brew = "curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    public let which_brew = "which brew"
    public let brew_update = "brew update"
    
    public let list = "brew list"
    public let list_formula = "brew list --formulae"
    public let list_cask = "brew list --cask"
    
    public let list_oudated = "brew outdated --json"
    public let list_oudated_formulae = "brew outdated --formula --json"
    public let list_oudated_casks = "brew outdated --cask --json"

    public func install(_ token: String) -> String {
        "brew install \(token)\n"
    }
    public func install_cask(_ token: String) -> String {
        "brew install --cask \(token)\n"
    }
    public func upgrade(_ token: String) -> String {
        "brew upgrade \(token)\n"
    }
    public func uninstall(_ token: String) -> String {
        "brew uninstall \(token)\n"
    }
    
    /// Disable the Zsh Line Editor (ZLE)
    public let disable_zle = "unsetopt zle\n"
    /// Disable the Carriage Return & the adding of a space in prompts
    public let disable_cr_sp = "unsetopt prompt_cr prompt_sp\n"
    /// Disable the special interpretation of the percent sign
    public let disable_prct = "setopt no_prompt_percent\n"
    /// Define a unique, static string to be used as the command prompt
    public let define_endpoint = "PROMPT='__END_OF_COMMAND__'\n"


//    public let brew_list = "brew list\n"
//    public let brew_list_formula = "brew list --formulae\n"
//    public let brew_list_cask = "brew list --cask\n"
//    
//    public let brew_list_oudated = "brew outdated --json\n"
//    public let brew_list_oudated_formulae = "brew outdated --formula --json\n"
//    public let brew_list_oudated_casks = "brew outdated --cask --json\n"
//
//    public func brew_install(token: String) -> String {
//        "brew install \(token)\n"
//    }
//    public func brew_install_cask(token: String) -> String {
//        "brew install --cask \(token)\n"
//    }
//    public func brew_upgrade(token: String) -> String {
//        "brew upgrade \(token)\n"
//    }
//    public func brew_uninstall(token: String) -> String {
//        "brew unistall \(token)\n"
//    }
}
