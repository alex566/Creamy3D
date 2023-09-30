//
//  Material.swift
// 
//
//  Created by Alexey Oleynik on 29.09.23.
//

import Foundation

public protocol MeshMaterial {
    var alpha: CGFloat { get }
    var blend: MeshMaterialBlend { get }
    
    func makeFunction() -> MaterialFunction
}

public extension MeshMaterial {
    
    var alpha: CGFloat {
        1.0
    }
    
    var blend: MeshMaterialBlend {
        .normal
    }
}

@resultBuilder
public enum MeshMaterialBuilder {
    
    public func buildBlock() -> [any MeshMaterial] {
        [ColorMaterial(color: .black)]
    }
    
    public static func buildBlock(_ components: any MeshMaterial...) -> [any MeshMaterial] {
        components
    }
}
