//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 01.10.23.
//

import Metal
import MetalKit

private struct FresnelMaterialArguments {
    var color: SIMD3<Float>
    var intensity: Float
    var scale: Float
    var bias: Float
}

final class FresnelMaterialFunction: MaterialFunction {
    let color: SIMD3<Float>
    let intensity: CGFloat
    let scale: CGFloat
    let bias: CGFloat
    
    init(color: SIMD3<Float>, bias: CGFloat, scale: CGFloat, intensity: CGFloat) {
        self.color = color
        self.scale = scale
        self.intensity = intensity
        self.bias = bias
    }
    
    var functionName: String {
        "fresnel_material"
    }
    
    func loadResources(textureLoader: MTKTextureLoader) throws {
    }
    
    var resourcesSize: Int {
        MemoryLayout<FresnelMaterialArguments>.stride
    }
    
    func assignResources(pointer: UnsafeMutableRawPointer) {
        let binded = pointer.bindMemory(to: FresnelMaterialArguments.self, capacity: 1)
        binded.pointee.intensity = Float(intensity)
        binded.pointee.color = color
        binded.pointee.scale = Float(scale)
        binded.pointee.bias = Float(bias)
    }
    
    func useResources(encoder: MTLRenderCommandEncoder) {
    }
}
