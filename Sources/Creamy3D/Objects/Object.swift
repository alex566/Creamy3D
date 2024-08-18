//
//  Object.swift
// 
//
//  Created by Alexey Oleynik on 29.09.23.
//

import Foundation

public protocol Object {
}

@resultBuilder
public enum ObjectBuilder {
    
    public static func buildBlock(_ objects: Object...) -> [any Object] {
        objects
    }
}
