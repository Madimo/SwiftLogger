//
//  SwiftLogger.swift
//  SwiftLogger
//
//
//  Created by Madimo on 2021/3/9.
//  Copyright © 2021 Madimo. All rights reserved.
//

import Foundation

public protocol LoggerInterface {
    func log(_ log: Log) -> Log
}

extension LoggerInterface {

    @discardableResult
    public func log(
        _ item: Any,
        level: Level,
        module: Module = .default,
        date: Date = Date(),
        file: String = #file,
        line: Int = #line,
        column: Int = #column,
        function: String = #function
    ) -> Log {
        log(.init(
            message: String(describing: item),
            date: date,
            level: level,
            module: module,
            file: (file as NSString).lastPathComponent,
            line: line,
            column: column,
            function: function
        ))
    }

    /// Designates finer-grained informational events than the `debug`.
    @discardableResult
    public func trace(
        _ item: Any,
        module: Module = .default,
        file: String = #file,
        line: Int = #line,
        column: Int = #column,
        function: String = #function
    ) -> Log {
        log(
            item,
            level: .trace,
            module: module,
            file: file,
            line: line,
            column: column,
            function: function
        )
    }

    /// Designates fine-grained informational events that are most useful to debug an application.
    @discardableResult
    public func debug(
        _ item: Any,
        module: Module = .default,
        file: String = #file,
        line: Int = #line,
        column: Int = #column,
        function: String = #function
    ) -> Log {
        log(
            item,
            level: .debug,
            module: module,
            file: file,
            line: line,
            column: column,
            function: function
        )
    }

    /// Designates informational messages that highlight the progress of the application at coarse-grained level.
    @discardableResult
    public func info(
        _ item: Any,
        module: Module = .default,
        file: String = #file,
        line: Int = #line,
        column: Int = #column,
        function: String = #function
    ) -> Log {
        log(
            item,
            level: .info,
            module: module,
            file: file,
            line: line,
            column: column,
            function: function
        )
    }

    /// Designates potentially harmful situations.
    @discardableResult
    public func warn(
        _ item: Any,
        module: Module = .default,
        file: String = #file,
        line: Int = #line,
        column: Int = #column,
        function: String = #function
    ) -> Log {
        log(
            item,
            level: .warn,
            module: module,
            file: file,
            line: line,
            column: column,
            function: function
        )
    }

    /// Designates error events that might still allow the application to continue running.
    @discardableResult
    public func error(
        _ item: Any,
        module: Module = .default,
        file: String = #file,
        line: Int = #line,
        column: Int = #column,
        function: String = #function
    ) -> Log {
        log(
            item,
            level: .error,
            module: module,
            file: file,
            line: line,
            column: column,
            function: function
        )
    }

    /// Designates very severe error events that will presumably lead the application to abort.
    @discardableResult
    public func fatal(
        _ item: Any,
        module: Module = .default,
        file: String = #file,
        line: Int = #line,
        column: Int = #column,
        function: String = #function
    ) -> Log {
        log(
            item,
            level: .fatal,
            module: module,
            file: file,
            line: line,
            column: column,
            function: function
        )
    }

}
