//
//  ConsoleLogHandler.swift
//  Logger
//  
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public final class ConsoleLogHandler: LogHandler {

    public let identifier: String
    public var isEnabled = true
    public lazy var filter: LogFilter = AllAcceptLogFilter()

    public lazy var logFormatter: LogFormatter = {
        let formatter = DefaultLogFormatter()
        formatter.showFile = false
        formatter.showLine = false
        formatter.showColumn = false
        formatter.showFunction = false
        formatter.dateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return formatter
        }()
        return formatter
    }()

    public init(identifier: String = "com.Madimo.Logger.ConsoleLogHandler") {
        self.identifier = identifier
    }

    public func write(_ log: Log) {
        print(logFormatter.format(log))
    }

}
