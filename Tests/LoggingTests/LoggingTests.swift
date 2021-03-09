//
//  SwiftLoggerTests.swift
//  SwiftLogger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import XCTest
@testable import Logging

final class LoggerTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false
    }

    private func waitLogQueue(timeout: TimeInterval = 10, file: String = #file, line: Int = #line) {
        let expectation = XCTestExpectation()
        Logger.logQueue.async {
            expectation.fulfill()
        }

        switch XCTWaiter.wait(for: [expectation], timeout: timeout) {
        case .timedOut:
            record(
                XCTIssue(
                    type: .thrownError,
                    compactDescription: "Wait for logger timed out.",
                    detailedDescription: nil,
                    sourceCodeContext: .init(
                        location: .init(
                            filePath: file,
                            lineNumber: line
                        )
                    ),
                    associatedError: nil,
                    attachments: []
                )
            )
        default:
            break
        }
    }

    func testAddAndRemoveLogHandler() {
        let logger = Logger()

        let identifier0 = "identifier0"
        let handler0 = TestLogHandler(identifier: identifier0)
        logger.add(handler: handler0)
        XCTAssertEqual(logger.handlers.count, 1)
        XCTAssertEqual(logger.handlers[0].identifier, identifier0)

        let identifier1 = "identifier1"
        let handler1 = TestLogHandler(identifier: identifier1)
        logger.add(handler: handler1)
        XCTAssertEqual(logger.handlers.count, 2)
        XCTAssertEqual(logger.handlers[0].identifier, identifier0)
        XCTAssertEqual(logger.handlers[1].identifier, identifier1)

        let handler2 = TestLogHandler(identifier: identifier1)
        logger.add(handler: handler2)
        XCTAssertEqual(logger.handlers.count, 2)
        XCTAssertEqual(logger.handlers[0].identifier, identifier0)
        XCTAssertEqual(logger.handlers[1].identifier, identifier1)

        logger.remove(handler: handler0)
        XCTAssertEqual(logger.handlers.count, 1)
        XCTAssertEqual(logger.handlers[0].identifier, identifier1)

        logger.remove(handler: handler1)
        XCTAssertTrue(logger.handlers.isEmpty)
    }

    func testLog() throws {
        let logger = Logger()
        let testHandler = TestLogHandler()
        logger.add(handler: testHandler)

        let item = 0
        let level = Level.debug
        let module = Module.default

        let log = logger.log(item, level: level, module: module)
        waitLogQueue()

        let lastLog = try XCTUnwrap(testHandler.lastLog)
        XCTAssertEqual(lastLog.message, String(item))
        XCTAssertEqual(lastLog.level, level)
        XCTAssertEqual(lastLog.date, log.date)
        XCTAssertEqual(lastLog.module, module)
        XCTAssertEqual(lastLog.file, log.file)
        XCTAssertEqual(lastLog.line, log.line)
        XCTAssertEqual(lastLog.column, log.column)
        XCTAssertEqual(lastLog.function, log.function)
    }

    func testLogLevel() {
        let logger = Logger()
        let testHandler = TestLogHandler()
        logger.add(handler: testHandler)

        let message = "This is a log message."

        logger.trace(message)
        waitLogQueue()
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .trace)

        logger.debug(message)
        waitLogQueue()
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .debug)

        logger.info(message)
        waitLogQueue()
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .info)

        logger.warn(message)
        waitLogQueue()
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .warn)

        logger.error(message)
        waitLogQueue()
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .error)

        logger.fatal(message)
        waitLogQueue()
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .fatal)
    }

    func testLoggerEnabled() {
        let logger = Logger()
        logger.isEnabled = false
        let testHandler = TestLogHandler()
        logger.add(handler: testHandler)

        logger.error(0)
        XCTAssertNil(testHandler.lastLog)
    }

    func testLogHandlerEnabled() {
        let logger = Logger()
        let testHandler = TestLogHandler()
        testHandler.isEnabled = false
        logger.add(handler: testHandler)

        logger.error(0)
        XCTAssertNil(testHandler.lastLog)
    }

    func testSubLogger() throws {
        let logger = Logger()
        let testHandler = TestLogHandler()
        logger.add(handler: testHandler)

        let defaultLevel = Level.trace
        let module = Module(name: "SubLogger")
        let subLogger = logger.getSubLogger(
            availableLevels: [.error],
            defaultLevel: defaultLevel,
            module: module
        )

        let message = "A log from SubLogger."
        subLogger.debug(message)
        waitLogQueue()

        let lastLog = try XCTUnwrap(testHandler.lastLog)
        XCTAssertEqual(lastLog.message, message)
        XCTAssertEqual(lastLog.level, defaultLevel)
        XCTAssertEqual(lastLog.module, module)
    }

    func testGeneralLogFilter() {
        let logger = Logger()
        let testHandler = TestLogHandler()
        testHandler.filter = GeneralLogFilter { Int($0.message) == nil }
        logger.add(handler: testHandler)

        logger.error(0)
        waitLogQueue()
        XCTAssertNil(testHandler.lastLog)

        logger.error("This is a log message.")
        waitLogQueue()
        XCTAssertNotNil(testHandler.lastLog)
    }

    func testConditionLogFilter() {
        let module = Module(name: "Test")
        let logger = Logger()
        let testHandler = TestLogHandler()
        testHandler.filter = ConditionLogFilter(
            messageKeyword: "test",
            includeLevels: [.error, .warn],
            includeModules: [module]
        )
        logger.add(handler: testHandler)

        let message0 = "this_is_test_log."
        let message1 = "this_is_a_log."

        logger.error(message0)
        waitLogQueue()
        XCTAssertNil(testHandler.lastLog)

        logger.info(message0, module: module)
        waitLogQueue()
        XCTAssertNil(testHandler.lastLog)

        logger.info(message1, module: module)
        waitLogQueue()
        XCTAssertNil(testHandler.lastLog)

        logger.error(message0, module: module)
        waitLogQueue()
        XCTAssertEqual(testHandler.lastLog?.message, message0)
    }

    func testModule() {
        let logger = Logger()
        let testHandler = TestLogHandler()
        logger.add(handler: testHandler)

        logger.error(0)
        waitLogQueue()
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.module), .default)

        let module = Module(name: "This is a module.")
        logger.error(0, module: module)
        waitLogQueue()
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.module), module)
    }

    func testSequenceLogHandler() {
        let logger = Logger()
        let sequenceLogHandler = SequenceLogHandler()
        logger.add(handler: sequenceLogHandler)

        XCTAssertTrue(sequenceLogHandler.logs.isEmpty)

        let message0 = 0
        logger.error(message0)
        waitLogQueue()
        XCTAssertEqual(sequenceLogHandler.logs.count, 1)
        XCTAssertEqual(sequenceLogHandler.logs[0].message, String(message0))

        let message1 = "This is a log message."
        logger.debug(message1)
        waitLogQueue()
        XCTAssertEqual(sequenceLogHandler.logs.count, 2)
        XCTAssertEqual(sequenceLogHandler.logs[1].message, message1)

        sequenceLogHandler.removeAll()
        XCTAssertTrue(sequenceLogHandler.logs.isEmpty)
    }

    func testSerializedLogHandler() throws {
        var expectation = XCTestExpectation()
        let logger = Logger()
        let fileName = UUID().uuidString + ".db"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let serializedLogHandler = try SerializedLogHandler(fileURL: fileURL)
        logger.add(handler: serializedLogHandler)

        do {
            expectation = .init()

            serializedLogHandler.getLogs(
                filter: ConditionLogFilter(),
                before: nil,
                count: 20,
                completion: {
                    XCTAssertTrue($0.isEmpty)
                    expectation.fulfill()
                }
            )

            wait(for: [expectation], timeout: 2)
        }

        do {
            expectation = .init()

            let log = logger.debug("🎉 This is a 'BIG' log message.")
            waitLogQueue()

            serializedLogHandler.getLogs(
                filter: ConditionLogFilter(
                    messageKeyword: nil,
                    includeLevels: Level.allCases,
                    includeModules: [.default]
                ),
                before: nil,
                count: 20,
                completion: { logs in
                    XCTAssertEqual(logs.count, 1)
                    XCTAssertEqual(logs[0].id, 1)
                    XCTAssertEqual(logs[0].log, log)

                    expectation.fulfill()
                }
            )

            wait(for: [expectation], timeout: 2)
        }

        do {
            let module1 = Module(name: "Module1")
            let module2 = Module(name: "Module2")

            logger.debug("[Hit] This should be filtered.", module: module1)
            logger.error("[Hit] This should be filtered.")
            logger.error("This should be filtered.", module: module1)
            let log0 = logger.error("[Hit] This should not be filtered.", module: module1)
            let log1 = logger.fatal("[Hit] This should not be filtered.", module: module2)

            expectation = .init()

            serializedLogHandler.getLogs(
                filter: ConditionLogFilter(
                    messageKeyword: "[Hit]",
                    includeLevels: [.error, .fatal],
                    includeModules: [module1, module2]
                ),
                before: nil,
                count: 20,
                completion: { logs in
                    XCTAssertEqual(logs.count, 2)

                    XCTAssertEqual(logs[0].id, 6)
                    XCTAssertEqual(logs[0].log, log1)

                    XCTAssertEqual(logs[1].id, 5)
                    XCTAssertEqual(logs[1].log, log0)

                    expectation.fulfill()
                }
            )

            wait(for: [expectation], timeout: 2)

            expectation = .init()

            serializedLogHandler.getLogs(
                filter: ConditionLogFilter(
                    messageKeyword: "[Hit]",
                    includeLevels: [.error, .fatal],
                    includeModules: [module1, module2]
                ),
                before: nil,
                count: 1,
                completion: { logs in
                    XCTAssertEqual(logs.count, 1)

                    XCTAssertEqual(logs[0].id, 6)
                    XCTAssertEqual(logs[0].log, log1)

                    expectation.fulfill()
                }
            )

            wait(for: [expectation], timeout: 2)

            var serializedLog: SerializedLog?
            expectation = .init()

            serializedLogHandler.getLogs(
                filter: ConditionLogFilter(
                    messageKeyword: "[Hit]",
                    includeLevels: [.error, .fatal],
                    includeModules: [module1, module2]
                ),
                before: SerializedLog(id: 6, log: log1),
                count: 20,
                completion: { logs in
                    XCTAssertEqual(logs.count, 1)

                    XCTAssertEqual(logs[0].id, 5)
                    XCTAssertEqual(logs[0].log, log0)
                    serializedLog = logs[0]

                    expectation.fulfill()
                }
            )

            wait(for: [expectation], timeout: 2)

            serializedLogHandler.deleteLogs([serializedLog!])
            waitLogQueue()

            expectation = .init()

            serializedLogHandler.getLogCount {
                XCTAssertEqual($0, 5)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2)
        }

        do {
            expectation = .init()

            var receivedLog: SerializedLog?
            let logListener = TestLogListener {
                receivedLog = $0
                expectation.fulfill()
            }
            serializedLogHandler.addLogListener(logListener)

            let log = logger.info("This is a log.")
            waitLogQueue()
            wait(for: [expectation], timeout: 2)

            XCTAssertEqual(receivedLog!.id, 7)
            XCTAssertEqual(receivedLog!.log, log)
        }

        do {
            serializedLogHandler.deleteAllLogs()
            waitLogQueue()

            expectation = .init()

            serializedLogHandler.getLogCount {
                XCTAssertEqual($0, 0)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2)
        }

        do {
            try serializedLogHandler.close()
            logger.info("This is another log message.")
            waitLogQueue()
            try serializedLogHandler.open()

            expectation = .init()

            serializedLogHandler.getLogCount {
                XCTAssertEqual($0, 0)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2)
        }
    }

    func testFileLogHandler() throws {
        let url =  URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".log")
        let fileLogHandler = try FileLogHandler(fileURL: url)
        let logger = Logger()
        logger.add(handler: fileLogHandler)

        var log = logger.log("This is a message.", level: .debug)
        waitLogQueue()
        fileLogHandler.close()

        var data = try XCTUnwrap(FileManager.default.contents(atPath: url.path))
        var text = try XCTUnwrap(String(data: data, encoding: .utf8))
        var logText = fileLogHandler.logFormatter.format(log) + "\n"
        XCTAssertEqual(logText, text)

        try fileLogHandler.open()
        log = logger.log("This is another message.", level: .debug)
        waitLogQueue()
        fileLogHandler.close()

        data = try XCTUnwrap(FileManager.default.contents(atPath: url.path))
        text = try XCTUnwrap(String(data: data, encoding: .utf8))
        logText += fileLogHandler.logFormatter.format(log) + "\n"
        XCTAssertEqual(logText, text)
    }

    func testSplitingFileLogHandler() throws {
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let _ = try SplitingFileLogHandler(directory: directoryURL)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)

        var files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        XCTAssertTrue(files.count == 1)

        var splitingFileLogHandler = try SplitingFileLogHandler(directory: directoryURL)
        XCTAssertTrue(splitingFileLogHandler.allLogFileURLs.count == 1)
        files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        XCTAssertTrue(files.count == 1)
        let currentFileURL = try XCTUnwrap(splitingFileLogHandler.currentLogFileURL)
        XCTAssertEqual(currentFileURL, files[0])
        splitingFileLogHandler.close()
        XCTAssertNil(splitingFileLogHandler.currentLogFileURL)

        let fileName = splitingFileLogHandler.fileNameFormatter.string(from: Date(timeIntervalSinceNow: -splitingFileLogHandler.minFileDateInterval - 2))
        try files.forEach { try FileManager.default.removeItem(at: $0) }
        let fileURL = directoryURL.appendingPathComponent(fileName).appendingPathExtension(splitingFileLogHandler.filePathExtension)
        FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)

        files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        XCTAssertTrue(files.count == 1)


        splitingFileLogHandler = try SplitingFileLogHandler(directory: directoryURL)
        files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        XCTAssertTrue(files.count == 2)
        XCTAssertTrue(splitingFileLogHandler.allLogFileURLs.count == 2)

        try splitingFileLogHandler.deleteCurrentLogFile()
        files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        XCTAssertTrue(files.count == 2)
        XCTAssertTrue(splitingFileLogHandler.allLogFileURLs.count == 2)

        try splitingFileLogHandler.deleteAllLogFiles()
        files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        XCTAssertTrue(files.count == 1)
        XCTAssertTrue(splitingFileLogHandler.allLogFileURLs.count == 1)

        splitingFileLogHandler.close()
        try splitingFileLogHandler.deleteAllLogFiles()
        files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        XCTAssertTrue(files.count == 0)
        XCTAssertTrue(splitingFileLogHandler.allLogFileURLs.count == 0)
    }

    static var allTests = [
        ("testAddAndRemoveLogHandler", testAddAndRemoveLogHandler),
        ("testLog", testLog),
        ("testLogLevel", testLogLevel),
        ("testLoggerEnabled", testLoggerEnabled),
        ("testLogHandlerEnabled", testLogHandlerEnabled),
        ("testSubLogger", testSubLogger),
        ("testGeneralLogFilter", testGeneralLogFilter),
        ("testConditionLogFilter", testConditionLogFilter),
        ("testModule", testModule),
        ("testSequenceLogHandler", testSequenceLogHandler),
        ("testSerializedLogHandler", testSerializedLogHandler),
        ("testFileLogHandler", testFileLogHandler),
        ("testSplitingFileLogHandler", testSplitingFileLogHandler),
    ]

}
