//
//  Log.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public struct Log: Codable {

    public var message: String
    public var date: Date
    public var level: Level
    public var tag: Tag
    public var file: String
    public var line: Int
    public var column: Int
    public var function: String

}
