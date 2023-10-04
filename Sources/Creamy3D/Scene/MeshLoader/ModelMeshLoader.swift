//
//  ModelMeshLoader.swift
//  MilkWaves
//
//  Created by Alexey Oleynik on 29.09.23.
//

import MetalKit
import ModelIO

struct ModelMeshLoader: MeshLoader {
    let name: String
    let ext: String
    
    func load(device: MTLDevice, allocator: MTKMeshBufferAllocator) throws -> LoadedMesh {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            throw MeshLoadingError.fileNotFount
        }
        let asset = MDLAsset(
            url: url,
            vertexDescriptor: nil,
            bufferAllocator: allocator
        )
        guard let mesh = asset.object(at: 0) as? MDLMesh else {
            throw MeshLoadingError.incorrectStructure
        }
        mesh.vertexDescriptor = makeVertexDescriptor()
        mesh.addOrthTanBasis(
            forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
            normalAttributeNamed: MDLVertexAttributeNormal,
            tangentAttributeNamed: MDLVertexAttributeTangent
        )
        
        do {
            return .init(
                size: mesh.boundingBox.maxBounds - mesh.boundingBox.minBounds,
                mesh: try MTKMesh(mesh: mesh, device: device)
            )
        } catch {
            throw MeshLoadingError.loadingFailed
        }
    }
}
