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
    public var autoDeleteOutdatedLogs = true
    public var outdatedLogDate = Date(timeIntervalSinceNow: -5 * 24 * 3600)

    public var isClosed: Bool {
        db == nil
    }

    private let tableName = "Logs"
    private var db: OpaquePointer?
    private var enabled = true

    public var logs: [Log] {
        guard let db = db else { return [] }

        let count: Int = {
            var stmt: OpaquePointer?

            if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM \(tableName)", -1, &stmt, nil) == SQLITE_OK {
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
            SELECT message, date, level, tag, file, line, column, function FROM \(tableName) ORDER BY id DESC
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
            CREATE TABLE IF NOT EXISTS \(tableName) (
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

        Logger.logQueue.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }

            if self.autoDeleteOutdatedLogs {
                self.deleteOutdatedLogs()
            }
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
            INSERT INTO \(tableName) (message, date, level, tag, file, line, column, function) VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?
            )
            """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logErrorMessage()
            return
        }

        sqlite3_bind_string(stmt, 1, log.message)
        sqlite3_bind_double(stmt, 2, log.date.timeIntervalSince1970)
        sqlite3_bind_int(stmt, 3, log.level.rawValue)
        sqlite3_bind_string(stmt, 4, log.tag.name)
        sqlite3_bind_string(stmt, 5, log.file)
        sqlite3_bind_int(stmt, 6, log.line)
        sqlite3_bind_int(stmt, 7, log.column)
        sqlite3_bind_string(stmt, 8, log.function)

        if sqlite3_step(stmt) != SQLITE_DONE {
            logErrorMessage()
        }

        sqlite3_finalize(stmt)
    }

    public func deleteAllLogs() {
        Logger.logQueue.async { [weak self] in
            self?.onDeleteAllLogs()
        }
    }

    private func onDeleteAllLogs() {
        guard let db = db else { return }

        let sql = """
            DELETE FROM \(tableName)
            """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            logErrorMessage()
        }
    }

    public func deleteOutdatedLogs() {
        Logger.logQueue.async { [weak self] in
            self?.onDeleteOutdatedLogs()
        }
    }

    private func onDeleteOutdatedLogs() {
        guard let db = db else { return }

        let sql = """
            DELETE FROM \(tableName) WHERE date < \(outdatedLogDate.timeIntervalSince1970)
            """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            logErrorMessage()
        }
    }

    @discardableResult
    private func logErrorMessage() -> String {
        guard let db = db else { return "" }

        let message = String(cString: sqlite3_errmsg(db))
        Logger.default.error(message)
        return message
    }

}

// MARK: - SQLite3

extension SerializedLogHandler {

    private func sqlite3_column_string(_ stmt: OpaquePointer!, _ column: Int32) -> String {
        String(cString: sqlite3_column_text(stmt, column))
    }

    private func sqlite3_column_int(_ stmt: OpaquePointer!, _ column: Int32) -> Int {
        #if arch(x86_64) || arch(arm64)
        return Int(SQLite3.sqlite3_column_int64(stmt, column))
        #else
        return Int(SQLite3.sqlite3_column_int(stmt, column))
        #endif
    }

    @discardableResult
    private func sqlite3_bind_int(_ stmt: OpaquePointer!, _ bindIndex: Int32, _ value: Int) -> Int32 {
        #if arch(x86_64) || arch(arm64)
        return sqlite3_bind_int64(stmt, bindIndex, Int64(value))
        #else
        return sqlite3_bind_int32(stmt, bindIndex, Int32(value))
        #endif
    }

    @discardableResult
    private func sqlite3_bind_string(
        _ stmt: OpaquePointer!,
        _ bindIndex: Int32,
        _ value: String
    ) -> Int32 {
        sqlite3_bind_text(
            stmt,
            bindIndex,
            value,
            -1,
            unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        )
    }

}

// MARK: -

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
