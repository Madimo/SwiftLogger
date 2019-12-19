//
//  Logger.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public final class Logger {

    public let identifier: String
    public var isEnabled = true

    public private(set) var handlers = [LogHandler]()
    public private(set) var triggers = [LogTrigger]()

    public init(identifier: String = "com.Madimo.Logger") {
        self.identifier = identifier
    }

    private func log(_ log: Log) -> Log {
        guard isEnabled else { return log }

        handlers
            .filter { $0.isEnabled }
            .filter { log.level >= $0.outputLevel }
            .filter { $0.filter?(log) ?? true }
            .forEach {
                $0.write(log)
            }

        return log
    }

    @discardableResult
    public func log(_ item: Any, level: Level, tag: Tag = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(.init(
            message: String(describing: item),
            date: Date(),
            level: level,
            tag: tag,
            file: (file as NSString).lastPathComponent,
            line: line,
            column: column,
            function: function
        ))
    }

    @discardableResult
    public func info(_ item: Any, tag: Tag = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .info, tag: tag, file: file, line: line, column: column, function: function)
    }

    @discardableResult
    public func debug(_ item: Any, tag: Tag = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .debug, tag: tag, file: file, line: line, column: column, function: function)
    }

    @discardableResult
    public func warning(_ item: Any, tag: Tag = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .warning, tag: tag, file: file, line: line, column: column, function: function)
    }

    @discardableResult
    public func error(_ item: Any, tag: Tag = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .error, tag: tag, file: file, line: line, column: column, function: function)
    }

    @discardableResult
    public func fatal(_ item: Any, tag: Tag = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .fatal, tag: tag, file: file, line: line, column: column, function: function)
    }

    @discardableResult
    public func trace(_ item: Any, tag: Tag = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .trace, tag: tag, file: file, line: line, column: column, function: function)
    }

    public func add(handler: LogHandler) {
        guard handlers.first(where: { $0.identifier == handler.identifier }) == nil else { return }

        handlers.append(handler)
    }

    public func remove(handler: LogHandler) {
        handlers.removeAll(where: { $0.identifier == handler.identifier })
    }

    public func add(trigger: LogTrigger) {
        guard triggers.first(where: { $0.identifier == trigger.identifier }) == nil else { return }

        triggers.append(trigger)
        trigger.receive(logger: self)
    }

    public func remove(trigger: LogTrigger) {
        if let index = triggers.firstIndex(where: { $0.identifier == trigger.identifier }) {
            triggers.remove(at: index)
            trigger.remove(logger: self)
        }
    }

}

extension Logger {

    static var `default`: Logger = {
        let logger = Logger(identifier: "com.Madimo.Logger.Default")
        
        let consoleLogHandler = ConsoleLogHandler()
        consoleLogHandler.logFormatter = {
            let formatter = DefaultLogFormatter()
            formatter.showFile = false
            return formatter
        }()
        logger.add(handler: consoleLogHandler)

        return logger
    }()

}
