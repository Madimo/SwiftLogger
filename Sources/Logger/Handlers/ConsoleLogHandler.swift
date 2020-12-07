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

    public let identifier = "com.Madimo.Logger.ConsoleLogHandler"
    public var outputLevel = Level.trace
    public var isEnabled = true
    public lazy var filter: LogFilter = AllAcceptLogFilter()
    public lazy var logFormatter: LogFormatter = DefaultLogFormatter()

    public init() {
        
    }

    public func write(_ log: Log) {
        print(logFormatter.format(log))
    }

}
