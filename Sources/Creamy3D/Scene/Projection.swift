//
//  File.swift
//
//
//  Created by Alexey Oleynik on 29.09.23.
//

import simd
import CoreGraphics
import Spatial

struct Projection {
    let width: CGFloat
    let height: CGFloat
    let nearZ: Float
    let farZ: Float
    
    func makeMatrix() -> float4x4 {
        Self.orthographicProjection(
            width: Float(width),
            height: Float(height),
            nearZ: nearZ,
            farZ: farZ
        )
    }
    
    private static func orthographicProjection(width: Float,
                                               height: Float,
                                               nearZ: Float,
                                               farZ: Float) -> float4x4 {
        
        let scaleX = 2.0 / width // Scaled to the metal viewport
        let scaleY = -2.0 / height
        let scaleZ = 1.0 / (nearZ - farZ)

//        let offsetX = Float(-1.0) // Shift to the left side
//        let offsetY = Float(1.0) // Shift to the top
        let offsetX = Float(0.0)
        let offsetY = Float(0.0)
        let offsetZ = -nearZ / (nearZ - farZ)

        let matrix = simd_float4x4(
            [scaleX, 0, 0, 0],
            [0, scaleY, 0, 0],
            [0, 0, scaleZ, 0],
            [offsetX, offsetY, offsetZ, 1]
        )

        return matrix
    }
}
