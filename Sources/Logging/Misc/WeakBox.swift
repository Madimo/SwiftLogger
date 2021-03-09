//
//  WeakBox.swift
//  
//
//  Created by Madimo on 2020/12/8.
//

import Foundation

struct WeakBox<T: AnyObject> {

    weak var value: T?

}
