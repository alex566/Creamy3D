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
        config: Renderer.Config,
        allocator: MTKMeshBufferAllocator,
        textureLoader: MTKTextureLoader,
        device: MTLDevice,
        library: MTLLibrary
    ) throws {
        let loader = mesh.loader()
        self.mesh = try loader.load(device: device, allocator: allocator)
        
        let state = MaterialState()
        try state.setup(
            materials: mesh.materials, 
            config: config,
            device: device,
            library: library,
            textureLoader: textureLoader
        )
        self.materialState = state
    }
    
    func update(
        mesh: Mesh,
        rect: CGRect
    ) {
        let options = mesh.options
        self.position = .init(Float(rect.midX), Float(rect.midY), 0.0)
//        self.position = .init(100.0, 0.0, 0.0)
        self.rotation = .init(
            angle: Float(options.rotation.0.radians),
            axis: .init(options.rotation.1)
        )
        self.scale = calculateScale(rect: rect)
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
        for mtkSubmesh in mesh.submeshes {
            encoder.drawIndexedPrimitives(type: mtkSubmesh.primitiveType,
                                          indexCount: mtkSubmesh.indexCount,
                                          indexType: mtkSubmesh.indexType,
                                          indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                          indexBufferOffset: mtkSubmesh.indexBuffer.offset)
        }
    }
    
    // MARK: - Utils
    private func calculateScale(rect: CGRect) -> SIMD3<Float> {
        let frameSize = SIMD3(Float(rect.width), Float(rect.height), 30.0) // TODO:
        guard let mesh else {
            return frameSize
        }
        let meshSize = mesh.size
        let scale = frameSize / meshSize
        return scale
    }
}

extension SIMD4 {
    
    var xyz: SIMD3<Scalar> {
        .init(x, y, z)
    }
}

extension SIMD3 {
    
    var xy: SIMD2<Scalar> {
        .init(x, y)
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
