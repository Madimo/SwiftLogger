//
//  TestLogListener.swift
//  
//
//  Created by Madimo on 2020/12/8.
//

import Foundation
import Logging

class TestLogListener: LogListener {

    private let onReceiveLog: (SerializedLog) -> Void

    init(_ onReceiveLog: @escaping (SerializedLog) -> Void) {
        self.onReceiveLog = onReceiveLog
    }

    func receive(_ log: SerializedLog) {
        onReceiveLog(log)
    }

}
