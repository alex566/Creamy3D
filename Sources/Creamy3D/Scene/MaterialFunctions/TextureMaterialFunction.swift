//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 05.10.23.
//

import Metal
import MetalKit

private struct TextureMaterialArguments {
    var textureID: MTLResourceID
}

final class TextureMaterialFunction: MaterialFunction {
    let textureName: String
    
    init(textureName: String) {
        self.textureName = textureName
    }
    
    var texture: MTLTexture!
    
    var functionName: String {
        "texture_material"
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
        MemoryLayout<TextureMaterialArguments>.stride
    }
    
    func assignResources(pointer: UnsafeMutableRawPointer) {
        let binded = pointer.bindMemory(to: TextureMaterialArguments.self, capacity: 1)
        binded.pointee.textureID = texture.gpuResourceID
    }
    
    func update(to material: any MeshMaterial) {
    }
    
    func useResources(encoder: MTLRenderCommandEncoder) {
        encoder.useResource(texture, usage: .read, stages: .fragment)
    }
}
