//
//  LinuxMain.swift
//  SwiftLogger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import XCTest
import LoggerTests

var tests = [XCTestCaseEntry]()
tests += LoggerTests.allTests()
XCTMain(tests)
