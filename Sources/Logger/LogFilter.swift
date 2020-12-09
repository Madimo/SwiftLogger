//
//  LogFilter.swift
//  
//
//  Created by Madimo on 2020/12/7.
//

import Foundation

public protocol LogFilter {
    func contains(_ log: Log) -> Bool
}

// MARK: -

final public class AllAcceptLogFilter: LogFilter {

    public init() {

    }

    public func contains(_ log: Log) -> Bool {
        true
    }

}

// MARK: -

final public class GeneralLogFilter: LogFilter {

    private let filter: (Log) -> Bool

    public init(_ filter: @escaping (Log) -> Bool) {
        self.filter = filter
    }

    public func contains(_ log: Log) -> Bool {
        filter(log)
    }

}

// MARK: -

final public class ConditionLogFilter: LogFilter {

    public var messageKeyword: String?
    public var includeLevels: [Level]
    public var includeModules: [Module]

    public init(
        messageKeyword: String? = nil,
        includeLevels: [Level] = Level.allCases,
        includeModules: [Module] = [.default]
    ) {
        self.messageKeyword = messageKeyword
        self.includeLevels = includeLevels
        self.includeModules = includeModules
    }

    public func contains(_ log: Log) -> Bool {
        guard includeLevels.contains(log.level) else { return false }
        guard includeModules.contains(log.module) else { return false }

        if let keyword = messageKeyword, !keyword.isEmpty {
            return log.message.contains(keyword)
        }

        return true
    }

}
