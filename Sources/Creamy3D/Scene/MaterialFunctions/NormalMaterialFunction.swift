//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 02.09.24.
//

import Metal
import MetalKit

final class NormalMaterialFunction: MaterialFunction {
    
    var functionName: String {
        "normal_material"
    }
    
    func loadResources(textureLoader: MTKTextureLoader) throws {
    }
    
    var resourcesSize: Int {
        0
    }
    
    func assignResources(pointer: UnsafeMutableRawPointer) {
    }
    
    func update(to material: any MeshMaterial) {
    }
    
    func useResources(encoder: any MTLRenderCommandEncoder) {
    }
}
