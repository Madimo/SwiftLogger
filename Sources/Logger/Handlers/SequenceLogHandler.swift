//
//  SequenceLogHandler.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public final class SequenceLogHandler: LogHandler, LogPresentable {

    public var identifier: String
    public var outputLevel = Level.trace
    public var isEnabled = true
    public var filter: Filter?

    public private(set) var logs = [Log]()

    public init(identifier: String = "com.Madimo.Logger.SequenceLogHandler") {
        self.identifier = identifier
    }

    public func write(_ log: Log) {
        logs.append(log)
    }

    public func removeAll() {
        logs.removeAll()
    }

}
