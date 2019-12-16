//
//  Tag.swift
//  Logger
//
//
//  Created by Madimo on 2019/12/11.
//  Copyright © 2019 Madimo. All rights reserved.
//

import Foundation

public struct Tag: Codable, Hashable {

    public var name: String

    public init(name: String) {
        self.name = name
    }

}

extension Tag: Equatable {

    public static func ==(lhs: Tag, rhs: Tag) -> Bool {
        lhs.name == rhs.name
    }

}

extension Tag {

    public static let `default` = Tag(name: "Default")

}
