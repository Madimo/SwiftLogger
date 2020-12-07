//
//  LogFormatter.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public protocol LogFormatter {
    func format(_ log: Log) -> String
}

open class DefaultLogFormatter: LogFormatter {

    open var showDate = true
    open var showLevel = true
    open var showTag = true
    open var showDefaultTag = false
    open var showFile = true
    open var showLine = true
    open var showColumn = false
    open var showFunction = false

    open lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        return formatter
    }()

    public init() {

    }

    open func format(_ log: Log) -> String {
        var output = ""

        if showDate {
            output += dateFormatter.string(from: log.date)
            output += " "
        }

        if showFile {
            output += log.file

            if showLine {
                output += ":\(log.line)"

                if showColumn {
                    output += ":\(log.column)"
                }
            }

            output += " "
        }

        if showFunction {
            output += "<\(log.function)>"
        }

        if showTag {
            if showDefaultTag || log.tag != Tag.default {
                output += "[\(log.tag.name)]"
            }
        }

        if showLevel {
            output += "[\(log.level)]"
        }

        output += " "
        output += log.message

        return output
    }

}
