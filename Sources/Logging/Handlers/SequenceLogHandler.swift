//
//  SequenceLogHandler.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public final class SequenceLogHandler: LogHandler {

    public var identifier: String
    public var isEnabled = true
    public lazy var filter: LogFilter = AllAcceptLogFilter()

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
