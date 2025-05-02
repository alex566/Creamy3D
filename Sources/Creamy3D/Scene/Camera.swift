//
//  File.swift
//
//
//  Created by Alexey Oleynik on 29.09.23.
//

import simd
import Spatial

struct Camera {
    let position: simd_float3
    let rotation: Rotation3D
    let anchorZ: Float
    let viewMatrix: float4x4
    
    init(rotation: Rotation3D, position: simd_float3, anchorZ: Float = 0.0) {
        self.position = position
        self.rotation = rotation
        self.anchorZ = anchorZ
        
        // SwiftUI and Metal have different coordinate systems:
        // - SwiftUI: origin at top-left, +Y down
        // - Metal: origin at center, +Y up
        // The offset shifts Metal coordinates to match SwiftUI
        
        // Anchor for Z-axis rotation
        let anchorMatrix = float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, anchorZ, 1]
        )
        
        // Create rotation matrix
        let rotationMatrix = float4x4(simd_quatf(rotation))
        
        // Position translation
        let positionMatrix = float4x4(
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [position.x, position.y, position.z, 1]
        )
        
        // Combine transformations to match SwiftUI's rotation3DEffect behavior:
        // For a camera view matrix, we combine in reverse order of how objects transform
        let transform = positionMatrix * anchorMatrix.inverse * rotationMatrix * anchorMatrix
        self.viewMatrix = transform.inverse
    }
}
