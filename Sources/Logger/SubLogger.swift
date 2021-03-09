//
//  SubLogger.swift
//  Logger
//
//
//  Created by Madimo on 2021/3/9.
//  Copyright © 2021 Madimo. All rights reserved.
//

import Foundation

public final class SubLogger: LoggerInterface {

    private let logger: Logger
    private let defaultLevel: Level?
    private let availableLevels: [Level]
    private let module: Module?

    init(
        logger: Logger,
        availableLevels: [Level] = [],
        defaultLevel: Level? = nil,
        module: Module? = nil
    ) {
        self.logger = logger
        self.availableLevels = availableLevels
        self.defaultLevel = defaultLevel
        self.module = module
    }

    public func log(_ log: Log) -> Log {
        var log = log

        if !availableLevels.contains(log.level) {
            if let defaultLevel = defaultLevel {
                log.level = defaultLevel
            }
        }

        if let module = module {
            log.module = module
        }

        return logger.log(log)
    }

}
