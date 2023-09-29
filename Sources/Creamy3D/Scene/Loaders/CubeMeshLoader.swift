//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 29.09.23.
//

import MetalKit
import ModelIO

struct CubeMeshLoader: MeshLoader {
    let dimensions: SIMD3<Float>
    let segments: SIMD3<UInt32>
    
    func load(device: MTLDevice, allocator: MTKMeshBufferAllocator) throws -> LoadedMesh {
        let mesh = MDLMesh.newBox(
            withDimensions: dimensions,
            segments: segments,
            geometryType: .triangles,
            inwardNormals: false,
            allocator: allocator
        )
        mesh.vertexDescriptor = makeVertexDescriptor()
        
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
