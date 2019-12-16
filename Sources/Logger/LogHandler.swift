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

    typealias Filter = (Log) -> Bool

    var identifier: String { get }
    var outputLevel: Level { get set }
    var isEnabled: Bool { get set }
    var filter: Filter? { get set }

    func write(_ log: Log)

}

public protocol LogPresentable {

    var logs: [Log] { get }

}
