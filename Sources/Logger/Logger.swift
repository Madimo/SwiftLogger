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

    static let logQueue = DispatchQueue(label: "com.Madimo.Logger.logQueue", qos: .utility)

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
            .filter { $0.filter.contains(log) }
            .forEach {
                $0.write(log)
            }

        return log
    }

    @discardableResult
    public func log(_ item: Any, level: Level, module: Module = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(.init(
            message: String(describing: item),
            date: Date(),
            level: level,
            module: module,
            file: (file as NSString).lastPathComponent,
            line: line,
            column: column,
            function: function
        ))
    }

    /// Designates finer-grained informational events than the DEBUG.
    @discardableResult
    public func trace(_ item: Any, module: Module = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .trace, module: module, file: file, line: line, column: column, function: function)
    }

    /// Designates fine-grained informational events that are most useful to debug an application.
    @discardableResult
    public func debug(_ item: Any, module: Module = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .debug, module: module, file: file, line: line, column: column, function: function)
    }

    /// Designates informational messages that highlight the progress of the application at coarse-grained level.
    @discardableResult
    public func info(_ item: Any, module: Module = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .info, module: module, file: file, line: line, column: column, function: function)
    }

    /// Designates potentially harmful situations.
    @discardableResult
    public func warn(_ item: Any, module: Module = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .warn, module: module, file: file, line: line, column: column, function: function)
    }

    /// Designates error events that might still allow the application to continue running.
    @discardableResult
    public func error(_ item: Any, module: Module = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .error, module: module, file: file, line: line, column: column, function: function)
    }

    /// Designates very severe error events that will presumably lead the application to abort.
    @discardableResult
    public func fatal(_ item: Any, module: Module = .default, file: String = #file, line: Int = #line, column: Int = #column, function: String = #function) -> Log {
        log(item, level: .fatal, module: module, file: file, line: line, column: column, function: function)
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
