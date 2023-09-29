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
        self.position = calculatePosition(options: options)
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
        for mtkSubmesh in mesh.submeshes {
            encoder.drawIndexedPrimitives(type: mtkSubmesh.primitiveType,
                                          indexCount: mtkSubmesh.indexCount,
                                          indexType: mtkSubmesh.indexType,
                                          indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                          indexBufferOffset: mtkSubmesh.indexBuffer.offset)
        }
    }
    
    // MARK: - Utils
    private func calculateScale(options: Mesh.Options, projection: Projection) -> SIMD3<Float> {
        guard let mesh, options.isResizable else {
            return .zero
        }
        let frameSize = calculateSize(options: options, projection: projection)
        let meshSize = mesh.size.xy
        var scale = frameSize / meshSize
        
        if let aspectRatio = options.aspectRatio {
            let meshAspectRatio = CGFloat(meshSize.x / meshSize.y)
            let targetRatio = aspectRatio.0 ?? meshAspectRatio
            let frameRation = CGFloat(frameSize.x / frameSize.y)
            
            switch aspectRatio.1 {
            case .fit:
                if targetRatio > frameRation {
                    scale.y = scale.y * Float(frameRation / targetRatio)
                } else {
                    scale.x = scale.x * Float(targetRatio / frameRation)
                }
            case .fill:
                if targetRatio > frameRation {
                    scale.x = scale.x / Float(frameRation / targetRatio)
                } else {
                    scale.y = scale.y / Float(targetRatio / frameRation)
                }
            }
        }
        
        return .init(scale.x, scale.y, min(scale.x, scale.y))
    }
    
    private func calculateSize(options: Mesh.Options, projection: Projection) -> SIMD2<Float> {
        let horizontalInset = options.insets.leading + options.insets.trailing
        let verticalInsets = options.insets.top + options.insets.bottom
        let frameWidth = options.frame?.width ?? projection.width
        let frameHeight = options.frame?.height ?? projection.height
        
        return .init(
            Float(frameWidth - horizontalInset),
            Float(frameHeight - verticalInsets)
        )
    }
    
    private func calculatePosition(options: Mesh.Options) -> SIMD3<Float> {
        .init(
            Float(options.offset.width + options.insets.leading / 2.0 - options.insets.trailing / 2.0),
            Float(options.offset.height + options.insets.top / 2.0 - options.insets.bottom / 2.0),
            0.0
        )
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
