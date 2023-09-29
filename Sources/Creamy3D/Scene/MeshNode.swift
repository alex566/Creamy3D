//
//  MeshNode.swift
//
//
//  Created by Alexey Oleynik on 29.09.23.
//

import simd
import MetalKit

struct MeshUniforms {
    let mvp: float4x4
    let model: float4x4
    let view: float4x4
    let normalModel: float3x3
    let time: Float
}

final class MeshNode: Transformable {
    var position = simd_float3.zero
    var scale = simd_float3.one
    var rotation = simd_quatf()
    
    var mesh: LoadedMesh?
    var materialState: MaterialState?
}

extension MeshNode: Renderable {
    
    func setup(
        mesh: Mesh,
        allocator: MTKMeshBufferAllocator,
        textureLoader: MTKTextureLoader,
        device: MTLDevice,
        library: MTLLibrary
    ) throws {
        let loader = mesh.source.loader()
        self.mesh = try loader.load(device: device, allocator: allocator)
        
        if let material = mesh.material as? MatcapMaterial {
            let state = MaterialState(device: device, library: library)
            try state.setup(meshMaterial: material, textureLoader: textureLoader)
            self.materialState = state
        } else {
            fatalError("Unknown material")
        }
    }
    
    func update(
        mesh: Mesh,
        projection: Projection
    ) {
        let options = mesh.options
        self.position = .init(
            Float(options.offset.width),
            Float(options.offset.height),
            0.0
        )
        self.rotation = .init(
            angle: Float(options.rotation.0.radians),
            axis: .init(options.rotation.1)
        )
        self.scale = calculateScale(options: options, projection: projection)
    }
    
    func render(
        encoder: MTLRenderCommandEncoder,
        viewProjectionMatrix: float4x4,
        viewMatrix: float4x4,
        deltaTime: Double
    ) {
        guard let mesh = self.mesh?.mesh, let materialState else {
            return
        }
        var uniforms = MeshUniforms(
            mvp: viewProjectionMatrix * model,
            model: model,
            view: viewMatrix,
            normalModel: calculateNormalMatrix(model),
            time: Float(deltaTime)
        )
        
        // Set the pipeline state
        materialState.activate(encoder: encoder)

        // Set the vertex buffer and any required uniforms
        encoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<MeshUniforms>.stride, index: 3)

        // Draw the mesh using the index buffer
        let mtkSubmesh = mesh.submeshes[0]
        encoder.drawIndexedPrimitives(type: mtkSubmesh.primitiveType,
                                      indexCount: mtkSubmesh.indexCount,
                                      indexType: mtkSubmesh.indexType,
                                      indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                      indexBufferOffset: mtkSubmesh.indexBuffer.offset)
    }
    
    // MARK: - Utils
    private func calculateScale(options: Mesh.Options, projection: Projection) -> SIMD3<Float> {
        guard let mesh, options.isResizable else {
            return .zero
        }
        let viewSize = SIMD2<Float>(projection.width, projection.height)
        let size = SIMD2<Float>(mesh.size.x, mesh.size.y)
        var scale = viewSize / size
        
        if let aspectRatio = options.aspectRatio {
            switch aspectRatio {
            case let (aspectRatio, .fit):
                let meshAspectRatio = CGFloat(size.x / size.y)
                let targetRatio = aspectRatio ?? meshAspectRatio
                if targetRatio > meshAspectRatio {
                    scale.x = scale.y * Float(meshAspectRatio / targetRatio)
                } else {
                    scale.y = scale.x * Float(targetRatio / meshAspectRatio)
                }
            case let (aspectRatio, .fill):
                let meshAspectRatio = CGFloat(size.x / size.y)
                let targetRatio = aspectRatio ?? meshAspectRatio
                if targetRatio > meshAspectRatio {
                    scale.y = scale.x * Float(targetRatio / meshAspectRatio)
                } else {
                    scale.x = scale.y * Float(meshAspectRatio / targetRatio)
                }
            }
        }
        
        return .init(scale.x, scale.y, min(scale.x, scale.y))
    }
}

extension SIMD4 {
    
    var xyz: SIMD3<Scalar> {
        .init(x, y, z)
    }
}

func float4x4ToFloat3x3(_ matrix: float4x4) -> float3x3 {
    float3x3(matrix[0].xyz, matrix[1].xyz, matrix[2].xyz)
}

func calculateNormalMatrix(_ model: float4x4) -> float3x3 {
    float4x4ToFloat3x3(model).inverse.transpose
}

protocol Updatable {
    func update(deltaTime: Double)
}

protocol Renderable {
    func render(encoder: MTLRenderCommandEncoder,
                viewProjectionMatrix: float4x4,
                viewMatrix: float4x4,
                deltaTime: Double)
}

protocol Transformable {
    var position: simd_float3 { get }
    var scale: simd_float3 { get }
    var rotation: simd_quatf { get }
    
    var model: float4x4 { get }
}

extension Transformable {
    
    var model: float4x4 {
        let scaleMatrix = simd_float4x4(diagonal: simd_float4(scale, 1.0))
        var matrix = simd_mul(scaleMatrix, simd_float4x4(rotation))
        matrix.columns.3 = simd_float4(position, 1.0)
        return matrix
    }
}
