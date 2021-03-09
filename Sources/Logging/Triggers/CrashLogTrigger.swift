//
//  CrashLogTrigger.swift
//  SwiftLogger
//
//
//  Created by Madimo on 2019/12/18.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public final class CrashLogTrigger: LogTrigger {

    public static let shared = CrashLogTrigger()
    public let identifier = "com.Madimo.Logger.CrashLogTrigger"

    private var loggers = [Logger]()
    private var isCrashHandlersInited = false

    private init() {

    }

    private func initCrashHandlers() {
        setupCrashHandlers()
        isCrashHandlersInited = true
    }

    public func receive(logger: Logger) {
        if loggers.isEmpty, !isCrashHandlersInited {
            initCrashHandlers()
        }

        loggers.append(logger)
    }

    public func remove(logger: Logger) {
        loggers.removeAll(where: { $0.identifier == logger.identifier })
    }

    fileprivate func receive(exception: NSException) {
        let callbackSymbols: [String] = {
            if exception.name == signalExceptionName, let symbols = exception.userInfo?[signalExceptionCallbackSymbolsKey] as? [String] {
                return symbols
            } else {
                return exception.callStackSymbols
            }
        }()

        let message = """
            Exception: \(exception.name.rawValue).
            Reason: \(exception.reason ?? "<Empty>").
            Callback Stack:
            \(callbackSymbols.joined(separator: "\n"))
            """

        loggers.forEach {
            $0.fatal(message)
        }

        // ensure log handlers finish logging
        Logger.logQueue.sync {
            // do nothing
        }
    }

}

private let signalExceptionName = NSExceptionName("NSSignalException")
private let signalExceptionCallbackSymbolsKey = "callbackSymbols"
private var oldExceptionHandler: ((NSException) -> Void)?
private var oldSigactions = [Int32 : Any]()

private let signals = [
    SIGABRT,
    SIGBUS,
    SIGFPE,
    SIGILL,
    SIGSEGV,
]

private func setupCrashHandlers() {
    setupUncaughtExceptionHandler()
    setupSignalHandlers()
}

private func setupUncaughtExceptionHandler() {
    oldExceptionHandler = NSGetUncaughtExceptionHandler()
    NSSetUncaughtExceptionHandler(exceptionHandler(_:))
}

private func setupSignalHandlers() {
    signals.forEach {
        var action = sigaction()
        action.sa_flags = SA_SIGINFO | SA_NODEFER
        action.__sigaction_u.__sa_sigaction = signalHandler(_:_:_:)

        var oldAction = sigaction()
        sigaction($0, &action, &oldAction)
        oldSigactions[$0] = oldAction
    }
}

private func unsetupSignalHandlers() {
    signals.forEach {
        signal($0, SIG_DFL)
    }
}

private func exceptionHandler(_ exception: NSException) {
    CrashLogTrigger.shared.receive(exception: exception)
    unsetupSignalHandlers()

    oldExceptionHandler?(exception)
}

private func signalHandler(_ signal: Int32, _ info: UnsafeMutablePointer<__siginfo>?, _ context: UnsafeMutableRawPointer?) {
    let reason: String = {
        switch signal {
        case SIGABRT:
            return "Abort"
        case SIGBUS:
            return "BUS Error"
        case SIGFPE:
            return "Floating Point Exception"
        case SIGILL:
            return "Illegal Instruction"
        case SIGSEGV:
            return "Segmentation Violation"
        default:
            return "Signal \(signal)"
        }
    }()

    let exception = NSException(
        name: signalExceptionName,
        reason: reason,
        userInfo: [signalExceptionCallbackSymbolsKey : Thread.callStackSymbols]
    )

    CrashLogTrigger.shared.receive(exception: exception)

    unsetupSignalHandlers()

    if let action = oldSigactions[signal] as? sigaction {
        if action.sa_flags & SA_SIGINFO > 0 {
            action.__sigaction_u.__sa_sigaction?(signal, info, context)
        } else {
            action.__sigaction_u.__sa_handler?(signal)
        }
    }
}
