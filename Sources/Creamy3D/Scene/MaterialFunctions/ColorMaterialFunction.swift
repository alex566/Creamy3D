//
//  ColorMaterialFunction.swift
//
//
//  Created by Alexey Oleynik on 30.09.23.
//

import Metal
import MetalKit

private struct ColorMaterialArguments {
    var color: SIMD3<Float>
}

final class ColorMaterialFunction: MaterialFunction {

    let color: SIMD3<Float>
    
    init(color: SIMD3<Float>) {
        self.color = color
    }
    
    var functionName: String {
        "color_material"
    }
    
    func loadResources(textureLoader: MTKTextureLoader) throws {
    }
    
    var resourcesSize: Int {
        MemoryLayout<ColorMaterialArguments>.stride
    }
    
    func assignResources(pointer: UnsafeMutableRawPointer) {
        let binded = pointer.bindMemory(to: ColorMaterialArguments.self, capacity: 1)
        binded.pointee.color = color
    }
    
    func useResources(encoder: MTLRenderCommandEncoder) {
    }
}
