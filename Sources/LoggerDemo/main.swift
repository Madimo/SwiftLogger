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
logger.add(handler: ConsoleLogHandler())

logger.info("Hello World!")
