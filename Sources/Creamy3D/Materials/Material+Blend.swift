//
//  Material+Blend.swift
//
//
//  Created by Alexey Oleynik on 01.10.23.
//

import Foundation

public enum MeshMaterialBlend {
    case normal, multiply, screen, overlay
}

public extension MeshMaterial {
    
    func blend(_ mode: MeshMaterialBlend = .normal, _ alpha: CGFloat) -> some MeshMaterial {
        BlendedMaterial(base: self, blend: mode, alpha: alpha)
    }
}

struct BlendedMaterial<Base: MeshMaterial>: MeshMaterial {
    let base: Base
    let blend: MeshMaterialBlend
    let alpha: CGFloat
    
    func makeFunction() -> MaterialFunction {
        base.makeFunction()
    }
}
