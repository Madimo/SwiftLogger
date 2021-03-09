//
//  LogHandler.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public protocol LogHandler {

    var identifier: String { get }
    var isEnabled: Bool { get set }
    var filter: LogFilter { get set }

    func write(_ log: Log)

}
