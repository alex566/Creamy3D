//
//  MatcapMaterialFunction.swift
//  
//
//  Created by Alexey Oleynik on 30.09.23.
//

import Metal
import MetalKit

private struct MatcapMaterialArguments {
    var textureID: MTLResourceID
}

final class MatcapMaterialFunction: MaterialFunction {
    let textureName: String
    
    init(textureName: String) {
        self.textureName = textureName
    }
    
    var texture: MTLTexture!
    
    var functionName: String {
        "matcap_material"
    }
    
    func loadResources(textureLoader: MTKTextureLoader) throws {
        do {
            texture = try textureLoader.newTexture(
                name: textureName,
                scaleFactor: 1.0,
                bundle: nil,
                options: [.SRGB: true]
            )
        } catch {
            throw MaterialFunctionError.failedToLoadResource
        }
    }
    
    var resourcesSize: Int {
        MemoryLayout<MatcapMaterialArguments>.stride
    }
    
    func assignResources(pointer: UnsafeMutableRawPointer) {
        let binded = pointer.bindMemory(to: MatcapMaterialArguments.self, capacity: 1)
        binded.pointee.textureID = texture.gpuResourceID
    }
    
    func update(to material: any MeshMaterial) {
    }
    
    func useResources(encoder: MTLRenderCommandEncoder) {
        encoder.useResource(texture, usage: .read, stages: .fragment)
    }
}

