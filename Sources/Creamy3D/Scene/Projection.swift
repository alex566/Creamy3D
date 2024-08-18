//
//  File.swift
//
//
//  Created by Alexey Oleynik on 29.09.23.
//

import simd
import CoreGraphics

struct Projection {
    let width: CGFloat
    let height: CGFloat
    let nearZ: Float
    let farZ: Float
    
    func makeMatrix() -> float4x4 {
        return Self.orthographicProjection(
            left: Float(-width / 2.0),
            right: Float(width / 2.0),
            bottom: Float(height / 2.0),
            top: Float(-height / 2.0),
            nearZ: nearZ,
            farZ: farZ
        )
    }
    
    private static func orthographicProjection(left: Float,
                                               right: Float,
                                               bottom: Float,
                                               top: Float,
                                               nearZ: Float,
                                               farZ: Float) -> float4x4 {
        let scaleX = 2.0 / (right - left)
        let scaleY = 2.0 / (top - bottom)  // Inverted Y-axis
        let scaleZ = 1.0 / (nearZ - farZ)

        let offsetX = -(right + left) / (right - left)
        let offsetY = -(top + bottom) / (top - bottom)
        let offsetZ = nearZ / (nearZ - farZ)

        let matrix = simd_float4x4(
            [scaleX, 0, 0, offsetX],
            [0, scaleY, 0, offsetY],
            [0, 0, scaleZ, offsetZ],
            [0, 0, 0, 1]
        )

        return matrix
    }
}
