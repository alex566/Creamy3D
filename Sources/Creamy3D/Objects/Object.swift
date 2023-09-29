//
//  Object.swift
//  MilkWaves
//
//  Created by Alexey Oleynik on 29.09.23.
//

import Foundation

public protocol Object {
}

@resultBuilder
public enum ObjectBuilder {
    
    public static func buildBlock() -> EmptyObject {
        .init()
    }
    
    public static func buildBlock<T: Object>(_ component: T) -> T {
        component
    }
}
