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
        // Create an orthographic projection that maps SwiftUI coordinates to Metal NDC
        // SwiftUI: origin at top-left (0,0), Y increasing downward
        // Metal NDC: origin at center, Y increasing upward, coordinates in [-1,1]
        
        // We need to:
        // 1. Scale [0,width] to [-1,1] for X
        // 2. Scale [0,height] to [1,-1] for Y (note the inversion)
        // 3. Scale [nearZ,farZ] appropriately for Z
        
        let scaleX = 2.0 / Float(width)    // Scale width to range of 2
        let scaleY = -2.0 / Float(height)  // Scale height to range of 2, flip Y
        let scaleZ = 1.0 / (nearZ - farZ)  // Scale Z to [0,1]
        
        // Origin translation
        let translateX = Float(-1.0)               // Map [0,width] → [-1,1]
        let translateY = Float(1.0)                // Map [0,height] → [1,-1]
        let translateZ = nearZ / (nearZ - farZ)
        
        return float4x4(
            [scaleX, 0, 0, 0],
            [0, scaleY, 0, 0],
            [0, 0, scaleZ, 0],
            [translateX, translateY, translateZ, 1]
        )
    }
}
