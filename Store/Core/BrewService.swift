//
//  BrewService.swift
//  Store
//
//  Created by Rodrigue de Guerre on 02/12/2025.
//
import Foundation


/// @V2: BrewService for improved reliability & segmentation
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
final class BrewService {}
