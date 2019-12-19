//
//  SerializedLogHandler.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation
import SQLite3

public final class SerializedLogHandler: LogHandler, LogPresentable {

    public var identifier: String
    public var outputLevel = Level.trace
    public var isEnabled: Bool = true
    public var filter: Filter?
    public let fileURL: URL

    public var isClosed: Bool {
        db == nil
    }

    private var db: OpaquePointer?
    private var enabled = true

    public var logs: [Log] {
        guard let db = db else { return [] }

        let count: Int = {
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM Logs", -1, &stmt, nil) == SQLITE_OK {
                var count = 0
                if sqlite3_step(stmt) == SQLITE_ROW {
                    count = sqlite3_column_int(stmt, 0)
                }

                sqlite3_finalize(stmt)
                return count
            } else {
                logErrorMessage()
            }

            return 0
        }()

        var logs = [Log]()
        if count > 0 {
            logs.reserveCapacity(count)
        }

        var stmt: OpaquePointer?
        let sql = """
            SELECT message, date, level, tag, file, line, column, function FROM Logs ORDER BY id DESC
        """

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                logs.append(Log(
                    message: sqlite3_column_string(stmt, 0),
                    date: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1)),
                    level: Level(rawValue: sqlite3_column_int(stmt, 2))!,
                    tag: Tag(name: sqlite3_column_string(stmt, 3)),
                    file: sqlite3_column_string(stmt, 4),
                    line: sqlite3_column_int(stmt, 5),
                    column: sqlite3_column_int(stmt, 6),
                    function: sqlite3_column_string(stmt, 7)
                ))
            }

            sqlite3_finalize(stmt)
        } else {
            logErrorMessage()
        }

        return logs
    }

    public init(identifier: String = "com.Madimo.Logger.SerializedLogHandler", fileURL: URL) throws {
        self.identifier = identifier
        self.fileURL = fileURL

        try open()
    }

    deinit {
        try? close()
    }

    public func write(_ log: Log) {
        Logger.logQueue.async {
            self.insert(log)
        }
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

        let result = sqlite3_open_v2(fileURL.absoluteString, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)

        guard result == SQLITE_OK, let db = db else {
            let message = logErrorMessage()
            throw HandlerError(reason: .databaseOpenFailed, message: message)
        }

        let sql = """
            CREATE TABLE IF NOT EXISTS Logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                message TEXT,
                date REAL NOT NULL,
                level INTEGER NOT NULL,
                tag Text,
                file Text,
                line INTEGER,
                column INTEGER,
                function TEXT
            )
        """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            let message = logErrorMessage()
            throw HandlerError(reason: .databaseOpenFailed, message: message)
        }
    }

    public func close() throws {
        guard db != nil else { return }

        if sqlite3_close_v2(db) == SQLITE_OK {
            db = nil
        } else {
            let message = logErrorMessage()
            throw HandlerError(reason: .databaseCloseFailed, message: message)
        }
    }

    private func insert(_ log: Log) {
        guard let db = db else { return }

        let sql = """
            INSERT INTO Logs (message, date, level, tag, file, line, column, function) VALUES (
                '\(encode(log.message))',
                \(log.date.timeIntervalSince1970),
                \(log.level.rawValue),
                '\(encode(log.tag.name))',
                '\(encode(log.file))',
                \(log.line),
                \(log.column),
                '\(encode(log.function))'
            )
        """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            logErrorMessage()
        }
    }

    public func truncate() throws {
        guard let db = db else { return }

        let sql = """
            DELETE FROM Logs
        """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            let message = logErrorMessage()
            throw HandlerError(reason: .databaseTruncateFailed, message: message)
        }
    }

    private func encode(_ text: String) -> String {
        text.replacingOccurrences(of: "'", with: "''")
    }

    private func sqlite3_column_string(_ stmt: OpaquePointer!, _ iCol: Int32) -> String {
        String(cString: sqlite3_column_text(stmt, iCol))
    }

    private func sqlite3_column_int(_ stmt: OpaquePointer!, _ iCol: Int32) -> Int {
        #if arch(x86_64) || arch(arm64)
        return Int(SQLite3.sqlite3_column_int64(stmt, iCol))
        #else
        return Int(SQLite3.sqlite3_column_int(stmt, iCol))
        #endif
    }

    @discardableResult
    private func logErrorMessage() -> String {
        guard let db = db else { return "" }

        let message = String(cString: sqlite3_errmsg(db))
        Logger.default.error(message)
        return message
    }

}

extension SerializedLogHandler {

    public struct HandlerError: Error {

        public enum Reason {
            case databaseOpenFailed
            case databaseCloseFailed
            case databaseTruncateFailed
        }

        public var reason: Reason
        public var message: String

    }

}
