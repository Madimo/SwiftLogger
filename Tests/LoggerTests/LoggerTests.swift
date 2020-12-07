//
//  LoggerTests.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import XCTest
@testable import Logger

final class LoggerTests: XCTestCase {

    func waitLogQueue(timeout: TimeInterval = 10, file: String = #file, line: Int = #line) {
        let expectation = XCTestExpectation()
        Logger.logQueue.async {
            expectation.fulfill()
        }

        switch XCTWaiter.wait(for: [expectation], timeout: timeout) {
        case .timedOut:
            recordFailure(withDescription: "Wait for logger timed out.", inFile: file, atLine: line, expected: true)
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
        let tag = Tag.default

        let log = logger.log(item, level: level, tag: tag)
        let lastLog = try XCTUnwrap(testHandler.lastLog)
        XCTAssertEqual(lastLog.message, String(item))
        XCTAssertEqual(lastLog.level, level)
        XCTAssertEqual(lastLog.date, log.date)
        XCTAssertEqual(lastLog.tag, tag)
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
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .trace)

        logger.debug(message)
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .debug)

        logger.info(message)
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .info)

        logger.warning(message)
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .warning)

        logger.error(message)
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .error)

        logger.fatal(message)
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .fatal)
    }

    func testOutputLevel() {
        let logger = Logger()
        let testHandler = TestLogHandler()
        testHandler.outputLevel = .warning
        logger.add(handler: testHandler)

        let message = "This is a log message."

        logger.trace(message)
        XCTAssertNil(testHandler.lastLog)

        logger.debug(message)
        XCTAssertNil(testHandler.lastLog)

        logger.info(message)
        XCTAssertNil(testHandler.lastLog)

        logger.warning(message)
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .warning)

        logger.error(message)
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.level), .error)

        logger.fatal(message)
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

    func testFilter() {
        let logger = Logger()
        let testHandler = TestLogHandler()
        testHandler.filter = { Int($0.message) == nil }
        logger.add(handler: testHandler)

        logger.error(0)
        XCTAssertNil(testHandler.lastLog)

        logger.error("This is a log message.")
        XCTAssertNotNil(testHandler.lastLog)
    }

    func testTag() {
        let logger = Logger()
        let testHandler = TestLogHandler()
        logger.add(handler: testHandler)

        logger.error(0)
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.tag), .default)

        let tag = Tag(name: "This is a tag.")
        logger.error(0, tag: tag)
        XCTAssertEqual(try XCTUnwrap(testHandler.lastLog?.tag), tag)
    }

    func testSequenceLogHandler() {
        let logger = Logger()
        let sequenceLogHandler = SequenceLogHandler()
        logger.add(handler: sequenceLogHandler)

        XCTAssertTrue(sequenceLogHandler.logs.isEmpty)

        let message0 = 0
        logger.error(message0)
        XCTAssertEqual(sequenceLogHandler.logs.count, 1)
        XCTAssertEqual(sequenceLogHandler.logs[0].message, String(message0))

        let message1 = "This is a log message."
        logger.debug(message1)
        XCTAssertEqual(sequenceLogHandler.logs.count, 2)
        XCTAssertEqual(sequenceLogHandler.logs[1].message, message1)

        sequenceLogHandler.removeAll()
        XCTAssertTrue(sequenceLogHandler.logs.isEmpty)
    }

    func testSerializedLogHandler() throws {
        let logger = Logger()
        let fileName = UUID().uuidString + ".db"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let serializedLogHandler = try SerializedLogHandler(fileURL: fileURL)
        logger.add(handler: serializedLogHandler)

        XCTAssertTrue(serializedLogHandler.logs.isEmpty)

        do {
            let log = logger.debug("This is a log message.")
            waitLogQueue()

            XCTAssertEqual(serializedLogHandler.logs.count, 1)
            XCTAssertEqual(serializedLogHandler.logs[0].message, log.message)
            XCTAssertEqual(Int(serializedLogHandler.logs[0].date.timeIntervalSince1970), Int(log.date.timeIntervalSince1970))
            XCTAssertEqual(serializedLogHandler.logs[0].level, log.level)
            XCTAssertEqual(serializedLogHandler.logs[0].tag, log.tag)
            XCTAssertEqual(serializedLogHandler.logs[0].file, log.file)
            XCTAssertEqual(serializedLogHandler.logs[0].line, log.line)
            XCTAssertEqual(serializedLogHandler.logs[0].column, log.column)
            XCTAssertEqual(serializedLogHandler.logs[0].function, log.function)
        }

        do {
            let log = logger.info("This is another\n\nlog message.")
            waitLogQueue()

            XCTAssertEqual(serializedLogHandler.logs[0].message, log.message)
        }

        do {
            let log = logger.info("🎉 This is a log message contains Emoji 😄.")
            waitLogQueue()

            XCTAssertEqual(serializedLogHandler.logs[0].message, log.message)
        }

        do {
            let log = logger.info("#//This is a log message contains '''?\"./*")
            waitLogQueue()

            XCTAssertEqual(serializedLogHandler.logs[0].message, log.message)
        }

        do {
            let log = logger.info("This is a log message contains 中文")
            waitLogQueue()

            XCTAssertEqual(serializedLogHandler.logs[0].message, log.message)
        }

        serializedLogHandler.deleteAllLogs()
        waitLogQueue()
        XCTAssertTrue(serializedLogHandler.logs.isEmpty)

        try serializedLogHandler.close()
        XCTAssertTrue(serializedLogHandler.logs.isEmpty)

        logger.info("This is another log message.")
        waitLogQueue()
        try serializedLogHandler.open()
        XCTAssertTrue(serializedLogHandler.logs.isEmpty)
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
        ("testOutputLevel", testOutputLevel),
        ("testLoggerEnabled", testLoggerEnabled),
        ("testLogHandlerEnabled", testLogHandlerEnabled),
        ("testFilter", testFilter),
        ("testTag", testTag),
        ("testSequenceLogHandler", testSequenceLogHandler),
        ("testSerializedLogHandler", testSerializedLogHandler),
        ("testSplitingFileLogHandler", testSplitingFileLogHandler),
    ]

}
