//
//  Sleep.swift
//  Manager
//
//  Created by Rodrigue de Guerre on 03/12/2025.
//

import Foundation


internal func sleep(_ duration: UInt64 = 10_000) async {
    try? await Task.sleep(nanoseconds: duration * 1_000)
}

internal func sleep(msec duration: UInt64) async {
    try? await Task.sleep(nanoseconds: duration * 1_000_000)
}

internal func sleep(sec duration: UInt64) async {
    try? await Task.sleep(nanoseconds: duration * 1_000_000_000)
}
