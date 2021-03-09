//
//  Logger.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public final class Logger: LoggerInterface {

    static let logQueue = DispatchQueue(label: "com.Madimo.Logger.logQueue", qos: .utility)

    public let identifier: String
    public var isEnabled = true

    public private(set) var handlers = [LogHandler]()
    public private(set) var triggers = [LogTrigger]()

    public init(identifier: String = "com.Madimo.Logger") {
        self.identifier = identifier
    }

    public func log(_ log: Log) -> Log {
        guard isEnabled else { return log }

        Self.logQueue.async { [self] in
            handlers
                .filter { $0.isEnabled }
                .filter { $0.filter.contains(log) }
                .forEach {
                    $0.write(log)
                }
        }

        return log
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

    public func getSubLogger(
        availableLevels: [Level] = [],
        defaultLevel: Level? = nil,
        module: Module? = nil
    ) -> SubLogger {
        .init(
            logger: self,
            availableLevels: availableLevels,
            defaultLevel: defaultLevel,
            module: module
        )
    }

}

extension Logger {

    static var `default`: Logger = {
        let logger = Logger(identifier: "com.Madimo.Logger.Default")
        logger.add(handler: ConsoleLogHandler())
        return logger
    }()

}
