//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 01.10.23.
//

import Foundation

public struct FresnelMaterial: MeshMaterial {
    let color: ColorRGB
    let intensity: CGFloat
    
    public init(color: ColorRGB, intensity: CGFloat) {
        self.color = color
        self.intensity = intensity
    }
    
    public func makeFunction() -> MaterialFunction {
        FresnelMaterialFunction(
            color: color.simd, 
            intensity: intensity
        )
    }
}
