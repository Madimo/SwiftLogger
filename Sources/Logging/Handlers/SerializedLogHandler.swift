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

public final class SerializedLogHandler: LogHandler {

    public var identifier: String
    public var isEnabled: Bool = true
    public lazy var filter: LogFilter = AllAcceptLogFilter()
    public let fileURL: URL
    public var autoDeleteOutdatedLogs = true
    public var outdatedLogDate = Date(timeIntervalSinceNow: -5 * 24 * 3600)

    public var isClosed: Bool {
        db == nil
    }

    private let tableName = "Logs"
    private var db: OpaquePointer?
    private var enabled = true
    private var logListeners = [WeakBox<AnyObject>]()

    public init(identifier: String = "com.Madimo.Logger.SerializedLogHandler", fileURL: URL) throws {
        self.identifier = identifier
        self.fileURL = fileURL

        try open()
    }

    deinit {
        try? close()
    }

    public func write(_ log: Log) {
        insert(log)
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
                module TEXT,
                file TEXT,
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
            INSERT INTO \(tableName) (message, date, level, module, file, line, column, function) VALUES (
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
        sqlite3_bind_string(stmt, 4, log.module.name)
        sqlite3_bind_string(stmt, 5, log.file)
        sqlite3_bind_int(stmt, 6, log.line)
        sqlite3_bind_int(stmt, 7, log.column)
        sqlite3_bind_string(stmt, 8, log.function)

        if sqlite3_step(stmt) != SQLITE_DONE {
            logErrorMessage()
        }

        sqlite3_finalize(stmt)

        let serializedLog = SerializedLog(id: Int(sqlite3_last_insert_rowid(db)), log: log)
        logListeners
            .compactMap { $0.value as? LogListener }
            .forEach {
                $0.receive(serializedLog)
            }
    }

    public func deleteOutdatedLogs() {
        Logger.logQueue.async { [self] in
            onDeleteOutdatedLogs()
        }
    }

    private func onDeleteOutdatedLogs() {
        guard let db = db else { return }

        let sql = """
            DELETE FROM \(tableName) WHERE date < \(outdatedLogDate.timeIntervalSince1970)
            """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            logErrorMessage( )
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

// MARK: - LogPresentable

extension SerializedLogHandler: LogPresentable {

    public func addLogListener(_ listener: LogListener) {
        logListeners.append(.init(value: listener))
    }

    public func removeLogListener(_ listener: LogListener) {
        logListeners.removeAll(where: { $0.value == nil || $0.value === listener })
    }

    public func getLogCount(_ completion: @escaping (Int) -> Void) {
        Logger.logQueue.async { [self] in
            onGetLogCount(completion)
        }
    }

    public func onGetLogCount(_ completion: @escaping (Int) -> Void) {
        guard let db = db else { return }

        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM \(tableName)", -1, &stmt, nil) == SQLITE_OK {
            var count = 0
            if sqlite3_step(stmt) == SQLITE_ROW {
                count = sqlite3_column_int(stmt, 0)
            }

            sqlite3_finalize(stmt)
            completion(count)
        } else {
            logErrorMessage()
        }
    }

    public func getLogs(filter: ConditionLogFilter, before: SerializedLog?, count: Int, completion: @escaping ([SerializedLog]) -> Void) {
        Logger.logQueue.async { [self] in
            onGetLogs(filter: filter, before: before, count: count, completion: completion)
        }
    }

    private func onGetLogs(filter: ConditionLogFilter, before: SerializedLog?, count: Int, completion: @escaping ([SerializedLog]) -> Void) {
        guard let db = db else { return }

        guard !filter.includeLevels.isEmpty else {
            completion([])
            return
        }

        guard !filter.includeModules.isEmpty else {
            completion([])
            return
        }

        var logs = [SerializedLog]()

        var whereExpression = ""
        whereExpression += "level IN (\(filter.includeLevels.map { String($0.rawValue) }.joined(separator: ",")))"
        whereExpression += " AND module IN (\(filter.includeModules.map { _ in "?" }.joined(separator: ",")))"

        if let messageKeyword = filter.messageKeyword, !messageKeyword.isEmpty {
            whereExpression += " AND message LIKE ?"
        }

        if let before = before {
            whereExpression += " AND id < \(before.id)"
        }

        var stmt: OpaquePointer?
        let sql = """
            SELECT id, message, date, level, module, file, line, column, function
            FROM \(tableName)
            WHERE \(whereExpression)
            ORDER BY id DESC
            LIMIT \(count)
            """

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logErrorMessage()
            return
        }

        var parameterIndex: Int32 = 1

        filter.includeModules.forEach {
            sqlite3_bind_string(stmt, parameterIndex, $0.name)
            parameterIndex += 1
        }

        if let messageKeyword = filter.messageKeyword, !messageKeyword.isEmpty {
            sqlite3_bind_string(stmt, parameterIndex, "%\(messageKeyword)%")
            parameterIndex += 1
        }

        while sqlite3_step(stmt) == SQLITE_ROW {
            logs.append(
                SerializedLog(
                    id: sqlite3_column_int(stmt, 0),
                    log: Log(
                        message: sqlite3_column_string(stmt, 1),
                        date: Date(timeIntervalSince1970: sqlite3_column_double(stmt, 2)),
                        level: Level(rawValue: sqlite3_column_int(stmt, 3))!,
                        module: Module(name: sqlite3_column_string(stmt, 4)),
                        file: sqlite3_column_string(stmt, 5),
                        line: sqlite3_column_int(stmt, 6),
                        column: sqlite3_column_int(stmt, 7),
                        function: sqlite3_column_string(stmt, 8)
                    )
                )
            )
        }

        sqlite3_finalize(stmt)
        completion(logs)
    }

    public func getAllModules(completion: @escaping ([Module]) -> Void) {
        Logger.logQueue.async { [self] in
            onGetAllModules(completion: completion)
        }
    }

    private func onGetAllModules(completion: @escaping ([Module]) -> Void) {
        var stmt: OpaquePointer?
        let sql = "SELECT module FROM \(tableName) GROUP BY module"

        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            var modules = [Module]()

            while sqlite3_step(stmt) == SQLITE_ROW {
                modules.append(.init(name: sqlite3_column_string(stmt, 0)))
            }

            sqlite3_finalize(stmt)
            completion(modules)
        } else {
            logErrorMessage()
        }
    }

    public func deleteLogs(_ logs: [SerializedLog]) {
        Logger.logQueue.async { [self] in
            onDeleteLogs(logs)
        }
    }

    private func onDeleteLogs(_ logs: [SerializedLog]) {
        guard let db = db else { return }

        let sql = """
            DELETE FROM \(tableName)
            WHERE id IN (\(logs.map { String($0.id) }.joined(separator: ",")))
            """

        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            logErrorMessage()
        }
    }

    public func deleteAllLogs() {
        Logger.logQueue.async { [self] in
            onDeleteAllLogs()
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

    public func export(completion: @escaping (URL) -> Void) {
        Logger.logQueue.async { [self] in
            onExport(completion: completion)
        }
    }

    private func onExport(completion: @escaping (URL) -> Void) {
        guard let db = db else { return }

        if sqlite3_db_cacheflush(db) != SQLITE_OK {
            logErrorMessage()
        }

        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMddHHmmss"

        let date = formatter.string(from: Date())
        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("Logs-\(date).db")

        try? FileManager.default.copyItem(at: fileURL, to: url)

        completion(url)
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
        return SQLite3.sqlite3_bind_int(stmt, bindIndex, Int32(value))
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
