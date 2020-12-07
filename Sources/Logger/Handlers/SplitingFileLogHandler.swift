//
//  SplitingFileLogHandler.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public final class SplitingFileLogHandler: LogHandler {

    public var identifier: String
    public var outputLevel = Level.trace
    public var isEnabled = true
    public lazy var filter: LogFilter = AllAcceptLogFilter()
    public let directory: URL
    public let fileNameFormatter: DateFormatter
    public let filePathExtension: String
    public let minFileDateInterval: TimeInterval

    public var isClosed: Bool {
        fileLogHandler == nil
    }

    public var allLogFileURLs: [URL] {
        allLogFiles.map { $0.url }
    }

    public var currentLogFileURL: URL? {
        fileLogHandler?.fileURL
    }

    private var allLogFiles = [(url: URL, date: Date)]()
    private var fileLogHandler: FileLogHandler?
    private var enabled = true

    init(identifier: String = "com.Madimo.Logger.SplitingFileLogHandler",
         directory: URL,
         fileNameFormatter: DateFormatter? = nil,
         filePathExtension: String = "log",
         minFileDateInterval: TimeInterval = 5 * 3600) throws {

        self.identifier = identifier
        self.directory = directory
        self.filePathExtension = filePathExtension
        self.minFileDateInterval = minFileDateInterval

        if let formatter = fileNameFormatter {
            self.fileNameFormatter = formatter
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            self.fileNameFormatter = formatter
        }

        try open()
    }

    public func open() throws {
        guard isClosed else { return }

        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        let date = Date()
        var fileURLs: [(url: URL, date: Date)] = try FileManager.default
            .contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            .filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == false }
            .filter { $0.pathExtension == filePathExtension }
            .compactMap { url -> (URL, Date)? in
                let fileName = url.deletingPathExtension().lastPathComponent

                if let fileDate = fileNameFormatter.date(from: fileName), fileDate <= date {
                    return (url, fileDate)
                }

                return nil
            }

        fileURLs.sort(by: { $0.date < $1.date })

        let logFileURL: URL
        if let max = fileURLs.last, date.timeIntervalSince1970 - max.date.timeIntervalSince1970 < minFileDateInterval {
            logFileURL = max.url
        } else {
            let fileName = fileNameFormatter.string(from: date) + ".log"
            logFileURL = directory.appendingPathComponent(fileName)
            fileURLs.append((logFileURL, date))

            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }

        fileLogHandler = try FileLogHandler(fileURL: logFileURL)
        allLogFiles = fileURLs
    }

    public func close() {
        fileLogHandler?.close()
        fileLogHandler = nil
    }

    public func deleteCurrentLogFile() throws {
        guard let fileURL = currentLogFileURL else { return }

        try deleteLogFile(at: fileURL)
    }

    public func deleteLogFile(at url: URL) throws {
        var shouldReopen = false
        if let current = currentLogFileURL, url == current {
            close()
            shouldReopen = true
        }

        if let index = allLogFiles.firstIndex(where: { $0.url == url }) {
            try FileManager.default.removeItem(at: url)
            allLogFiles.remove(at: index)
        }

        if shouldReopen {
            try open()
        }
    }

    public func deleteAllLogFiles() throws {
        try allLogFiles.forEach {
            try deleteLogFile(at: $0.url)
        }
    }

    public func write(_ log: Log) {
        fileLogHandler?.write(log)
    }

}
