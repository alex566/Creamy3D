//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 29.09.23.
//

import simd

struct Camera {
    let position: simd_float3
    let target: simd_float3
    let up: simd_float3
    
    func makeMatrix() -> float4x4 {
        let zAxis = normalize(position - target)
        let xAxis = normalize(cross(up, zAxis))
        let yAxis = cross(zAxis, xAxis)

        let matrix = simd_float4x4(
            simd_float4(xAxis.x, yAxis.x, zAxis.x, 0),
            simd_float4(xAxis.y, yAxis.y, zAxis.y, 0),
            simd_float4(xAxis.z, yAxis.z, zAxis.z, 0),
            simd_float4(-dot(xAxis, position), -dot(yAxis, position), -dot(zAxis, position), 1)
        )

        return matrix
    }
}
