//
//  SphereMeshLoader.swift
//  MilkWaves
//
//  Created by Alexey Oleynik on 29.09.23.
//

import MetalKit
import ModelIO

struct SphereMeshLoader: MeshLoader {
    let radii: SIMD3<Float>
    let radialSegments: Int
    let verticalSegments: Int
    
    func load(device: MTLDevice, allocator: MTKMeshBufferAllocator) throws -> LoadedMesh {
        let mesh = MDLMesh.newEllipsoid(
            withRadii: radii,
            radialSegments: radialSegments,
            verticalSegments: verticalSegments,
            geometryType: .triangles,
            inwardNormals: false,
            hemisphere: false,
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
