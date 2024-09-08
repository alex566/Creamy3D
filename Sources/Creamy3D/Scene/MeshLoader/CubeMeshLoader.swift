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
            geometryType: .quads,
            inwardNormals: false,
            allocator: allocator
        )
        mesh.vertexDescriptor = makeVertexDescriptor()
        
        mesh.addTangentBasis(
            forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
            normalAttributeNamed: MDLVertexAttributeNormal,
            tangentAttributeNamed: MDLVertexAttributeTangent
        )
        
        guard let submesh = mesh.submeshes?.firstObject as? MDLSubmesh else {
            fatalError("Couldn't find submesh in mesh")
        }
        
        return .init(
            size: mesh.boundingBox.maxBounds - mesh.boundingBox.minBounds,
            vertexCount: mesh.vertexCount,
            vertexBuffer: mesh.vertexBuffers[0] as! MTKMeshBuffer,
            vertexDescriptor: mesh.vertexDescriptor,
            indexBuffer: submesh.indexBuffer as! MTKMeshBuffer,
            indexType: .uint16
        )
    }
}
