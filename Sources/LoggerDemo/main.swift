//
//  main.swift
//  LoggerDemo
//
//
//  Created by Madimo on 2019/12/18.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation
import Logger

let logger = Logger()
logger.add(trigger: CrashLogTrigger.shared)
logger.add(handler: ConsoleLogHandler())
logger.add(handler: try! SerializedLogHandler(fileURL: URL(fileURLWithPath: "/Users/Madimo/Desktop/logs.db")))

logger.info("Hello World!")

NSArray().object(at: 1)
