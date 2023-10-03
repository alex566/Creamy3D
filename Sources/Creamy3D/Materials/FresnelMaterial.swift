//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 01.10.23.
//

import Foundation

public struct FresnelMaterial: MeshMaterial {
    let color: ColorRGB
    let scale: CGFloat
    let intensity: CGFloat
    
    public init(color: ColorRGB, scale: CGFloat = 1.0, intensity: CGFloat) {
        self.color = color
        self.scale = scale
        self.intensity = intensity
    }
    
    public func makeFunction() -> MaterialFunction {
        FresnelMaterialFunction(
            color: color.simd, 
            scale: scale,
            intensity: intensity
        )
    }
}
