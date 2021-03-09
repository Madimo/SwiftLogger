//
//  Level.swift
//  SwiftLogger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public enum Level: Int, Comparable, CustomStringConvertible, Codable, CaseIterable {

    /// Designates finer-grained informational events than the `debug`.
    case trace

    /// Designates fine-grained informational events that are most useful to debug an application.
    case debug

    /// Designates informational messages that highlight the progress of the application at coarse-grained level.
    case info

    /// Designates potentially harmful situations.
    case warn

    /// Designates error events that might still allow the application to continue running.
    case error

    /// Designates very severe error events that will presumably lead the application to abort.
    case fatal

    public static func < (lhs: Level, rhs: Level) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .trace: return "TRACE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        case .fatal: return "FATAL"
        }
    }

}
