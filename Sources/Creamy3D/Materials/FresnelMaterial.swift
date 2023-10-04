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
    let bias: CGFloat
    
    public init(
        color: ColorRGB,
        bias: CGFloat = 0.0,
        scale: CGFloat = 1.0,
        intensity: CGFloat
    ) {
        self.color = color
        self.scale = scale
        self.intensity = intensity
        self.bias = bias
    }
    
    public func makeFunction() -> MaterialFunction {
        FresnelMaterialFunction(
            color: color.SRGBToLinear().simd,
            bias: ColorRGB.sRGBToLinear(bias), 
            scale: scale,
            intensity: intensity
        )
    }
}
