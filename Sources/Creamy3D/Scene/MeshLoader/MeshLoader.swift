//
//  MeshLoader.swift
//  MilkWaves
//
//  Created by Alexey Oleynik on 29.09.23.
//

import MetalKit
import ModelIO

enum MeshLoadingError: Error {
    case fileNotFount
    case incorrectStructure
    case loadingFailed
}

struct LoadedMesh {
    let size: SIMD3<Float>
    let vertexCount: Int
    let vertexBuffer: MTKMeshBuffer
    let vertexDescriptor: MDLVertexDescriptor
    let indexBuffer: MTKMeshBuffer
    let indexType: MTLTessellationControlPointIndexType
}

protocol MeshLoader {
    func load(device: MTLDevice, allocator: MTKMeshBufferAllocator) throws -> LoadedMesh
    
    func makeVertexDescriptor() -> MDLVertexDescriptor
}

extension MeshLoader {
    
    func makeVertexDescriptor() -> MDLVertexDescriptor {
        let mdlVertexDescriptor = MDLVertexDescriptor()

        // Position attribute
        mdlVertexDescriptor.attributes[0] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float4,
            offset: 0,
            bufferIndex: 0
        )

        // Normal attribute
        let normalOffset = MemoryLayout<SIMD4<Float>>.stride 
        mdlVertexDescriptor.attributes[1] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: normalOffset,
            bufferIndex: 0
        )
        
        mdlVertexDescriptor.attributes[2] = MDLVertexAttribute(
            name: MDLVertexAttributeTangent,
            format: .float3,
            offset: MemoryLayout<SIMD4<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride,
            bufferIndex: 0
        )

        // UV attribute
        mdlVertexDescriptor.attributes[3] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: MemoryLayout<SIMD4<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride * 2,
            bufferIndex: 0
        )

        // Create a single interleaved buffer layout
        mdlVertexDescriptor.layouts[0] = MDLVertexBufferLayout(
            stride: MemoryLayout<SIMD4<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride * 2 + MemoryLayout<SIMD2<Float>>.stride
        )

        return mdlVertexDescriptor
    }
}

