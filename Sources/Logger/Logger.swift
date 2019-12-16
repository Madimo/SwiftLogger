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
    public var dispatchQueue: DispatchQueue
    public var isEnabled = true

    public private(set) var handlers = [LogHandler]()

    public init(
        identifier: String = "com.Madimo.Logger",
        dispatchQueue: DispatchQueue = DispatchQueue(label: "com.Madimo.Logger", qos: .utility)
    ) {
        self.identifier = identifier
        self.dispatchQueue = dispatchQueue
    }

    private func log(_ log: Log) -> Log {
        guard isEnabled else { return log }

        dispatchQueue.async {
            self.handlers
                .filter { $0.isEnabled }
                .filter { log.level >= $0.outputLevel }
                .filter { $0.filter?(log) ?? true }
                .forEach {
                    $0.write(log)
                }
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
