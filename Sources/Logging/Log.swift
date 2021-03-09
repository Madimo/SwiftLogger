//
//  Log.swift
//  SwiftLogger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public struct Log: Codable, Equatable {

    public var message: String
    public var date: Date
    public var level: Level
    public var module: Module
    public var file: String
    public var line: Int
    public var column: Int
    public var function: String

    public static func == (_ lhs: Log, _ rhs: Log) -> Bool {
        lhs.message == rhs.message &&
            fabs(lhs.date.timeIntervalSince1970 - rhs.date.timeIntervalSince1970) < Double.ulpOfOne &&
            lhs.level == rhs.level &&
            lhs.module == rhs.module &&
            lhs.file == rhs.file &&
            lhs.line == rhs.line &&
            lhs.column == rhs.column &&
            lhs.function == rhs.function
    }

}

public struct SerializedLog: Codable, Equatable {

    public var id: Int
    public var log: Log

}
