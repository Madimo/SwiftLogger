//
//  AppleConsoleLogHandler.swift
//  
//
//  Created by Madimo on 2020/12/9.
//

import Foundation
import os

public final class AppleConsoleLogHandler: LogHandler {

    public let identifier: String
    public var isEnabled = true
    public lazy var filter: LogFilter = AllAcceptLogFilter()
    public let subsystem: String

    public lazy var logFormatter: LogFormatter = {
        let formatter = DefaultLogFormatter()
        formatter.showDate = false
        formatter.showModule = false
        formatter.showFile = false
        return formatter
    }()

    public init(identifier: String = "com.Madimo.SwiftLogger.AppleConsoleLogHandler", subsystem: String) {
        self.identifier = identifier
        self.subsystem = subsystem
    }

    public func write(_ log: Log) {
        os_log(
            "%{public}s",
            log: OSLog(subsystem: subsystem, category: log.module.name),
            type: {
                switch log.level {
                case .trace:
                    return .default
                case .debug:
                    return .default
                case .info:
                    return .default
                case .warn:
                    return .error
                case .error:
                    return .error
                case .fatal:
                    return .fault
                }
            }(),
            logFormatter.format(log)
        )
    }

}
