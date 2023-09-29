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
    let mesh: MTKMesh
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
        mdlVertexDescriptor.attributes[1] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: MemoryLayout<SIMD4<Float>>.stride,
            bufferIndex: 0
        )

        // UV attribute
        mdlVertexDescriptor.attributes[2] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: MemoryLayout<SIMD4<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride,
            bufferIndex: 0
        )

        // Create a single interleaved buffer layout
        mdlVertexDescriptor.layouts[0] = MDLVertexBufferLayout(
            stride: MemoryLayout<SIMD4<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD2<Float>>.stride
        )

        return mdlVertexDescriptor
    }
}

extension Mesh.Source {
    
    func loader() -> any MeshLoader {
        switch self {
        case .sphere:
            return SphereMeshLoader(
                radii: .one,
                radialSegments: 100,
                verticalSegments: 100
            )
        case .cube:
            return CubeMeshLoader(
                dimensions: .one,
                segments: .one
            )
        case .obj(let name):
            return ModelMeshLoader(
                name: name,
                ext: "obj"
            )
        case .stl(let name):
            return ModelMeshLoader(
                name: name,
                ext: "stl"
            )
        }
    }
}
