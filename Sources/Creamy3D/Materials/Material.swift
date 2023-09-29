//
//  Material.swift
//  MilkWaves
//
//  Created by Alexey Oleynik on 29.09.23.
//

import Foundation

public protocol MeshMaterial {
}

@resultBuilder
public enum MeshMaterialBuilder {
    
    public static func buildBlock<T: MeshMaterial>(_ component: T) -> T {
        component
    }
}
