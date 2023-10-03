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
}

final class FresnelMaterialFunction: MaterialFunction {
    let color: SIMD3<Float>
    let intensity: CGFloat
    let scale: CGFloat
    
    init(color: SIMD3<Float>, scale: CGFloat, intensity: CGFloat) {
        self.color = color
        self.scale = scale
        self.intensity = intensity
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
    }
    
    func useResources(encoder: MTLRenderCommandEncoder) {
    }
}
