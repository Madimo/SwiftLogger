//
//  FileLogHandler.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public final class FileLogHandler: LogHandler {

    public let identifier: String
    public var outputLevel = Level.trace
    public var isEnabled = true
    public var filter: Filter?
    public lazy var logFormatter: LogFormatter = DefaultLogFormatter()
    public let fileURL: URL

    public var isClosed: Bool {
        fileHandle == nil
    }

    private var fileHandle: FileHandle?
    private var enabled = true

    public init(identifier: String = "com.Madimo.Logger.FileLogHandler", fileURL: URL) throws {
        self.identifier = identifier
        self.fileURL = fileURL

        try open()
    }

    deinit {
        close()
    }

    public func open() throws {
        guard isClosed else { return }

        let directory = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }

        fileHandle = try FileHandle(forUpdating: fileURL)
        fileHandle?.seekToEndOfFile()
    }

    public func close() {
        fileHandle?.closeFile()
        fileHandle = nil
    }

    public func write(_ log: Log) {
        guard let fileHandle = fileHandle else { return }

        let logText = logFormatter.format(log) + "\n"

        if let data = logText.data(using: .utf8) {
            fileHandle.write(data)
        }
    }

}
