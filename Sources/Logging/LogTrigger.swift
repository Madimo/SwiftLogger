//
//  LogTrigger.swift
//  SwiftLogger
//
//
//  Created by Madimo on 2019/12/18.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public protocol LogTrigger {

    var identifier: String { get }

    func receive(logger: Logger)
    func remove(logger: Logger)

}
