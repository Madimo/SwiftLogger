//
//  Module.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public struct Module: Codable, Hashable {

    public var name: String

    public init(name: String) {
        self.name = name
    }

}

extension Module: Equatable {

    public static func ==(lhs: Module, rhs: Module) -> Bool {
        lhs.name == rhs.name
    }

}

extension Module {

    public static let `default` = Module(name: "Default")

}
