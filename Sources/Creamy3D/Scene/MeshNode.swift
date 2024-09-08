//
//  MeshNode.swift
//
//
//  Created by Alexey Oleynik on 29.09.23.
//

import simd
import MetalKit
import SwiftUICore

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
    
    private let controlPointsPerPatch = 4 // quad
    private var patchCount = 0
    private var tessellationFactorBuffer: MTLBuffer!
    private var tessellationPipelineState: MTLComputePipelineState!
    
    private var shapePathBuffer: MTLBuffer!
    private var cornerPathBuffer: MTLBuffer!
}

extension MeshNode {
    
    func setup(
        mesh: Mesh,
        config: Renderer.Config,
        allocator: MTKMeshBufferAllocator,
        textureLoader: MTKTextureLoader,
        device: MTLDevice,
        library: MTLLibrary
    ) throws {
        let loader = mesh.loader()
        let loadedMesh = try loader.load(device: device, allocator: allocator)
        
        let state = MaterialState()
        
        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(loadedMesh.vertexDescriptor)!
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
        
        try state.setup(
            materials: mesh.materials,
            vertexDescriptor: vertexDescriptor,
            tessellationIndexType: loadedMesh.indexType,
            config: config,
            device: device,
            library: library,
            textureLoader: textureLoader
        )
        self.materialState = state
        self.mesh = loadedMesh
        
        self.patchCount = loadedMesh.vertexCount / controlPointsPerPatch
        self.tessellationFactorBuffer = device.makeBuffer(
            length: MemoryLayout<MTLQuadTessellationFactorsHalf>.stride * patchCount,
            options: .storageModePrivate
        )
        let computeFunction = library.makeFunction(name: "compute_tess_factors")!
        self.tessellationPipelineState = try device.makeComputePipelineState(function: computeFunction)
        
        // TODO: !!! Proper path buffer management
        self.shapePathBuffer = device.makeBuffer(
            length: MemoryLayout<ShapeSegment>.stride * 17,
            options: .storageModeShared
        )
        self.cornerPathBuffer = device.makeBuffer(
            length: MemoryLayout<ShapeSegment>.stride,
            options: .storageModeShared
        )
    }
    
    func update(
        mesh: Mesh,
        rect: CGRect
    ) {
        let options = mesh.options
        self.position = .init(Float(rect.midX), Float(rect.midY), 0.0)
        self.rotation = .init(
            angle: Float(options.rotation.0.radians),
            axis: .init(options.rotation.1)
        )
        self.scale = calculateScale(rect: rect)
        
        let start = Date()
        let shape = RoundedRectangle(cornerRadius: 32.0, style: .continuous)
        
        let shapeFrame = CGRect(
            origin: .init(x: -rect.width / 2.0, y: -rect.height / 2.0),
            size: rect.size
        )
        
        var path = ShapePath(path: shape.path(in: shapeFrame))
        path.multiply(by: .init(x: 1.0, y: 1.0) / self.scale.xy)
        let end = Date()
        print("ShapePath: \(end.timeIntervalSince(start)), segments: \(path.segments.count)")
        
        let pointer = self.shapePathBuffer.contents()
        memcpy(pointer, path.segments, MemoryLayout<ShapeSegment>.stride * path.segments.count)
        
        let cornerRadius = CGFloat(16.0)
        var cornerPath = ShapePath(
            path: Path { path in
                path.addRelativeArc(
                    center: .init(x: 0.0, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .radians(.pi / 2.0 * 3.0),
                    delta: .radians(.pi / 2.0)
                )
            }
        )
        cornerPath.multiply(by: .init(x: 1.0, y: 1.0) / self.scale.z)
        
        let pointer2 = self.cornerPathBuffer.contents()
        memcpy(pointer2, cornerPath.segments, MemoryLayout<ShapeSegment>.stride)
        
        materialState?.update(materials: mesh.materials)
    }
    
    // No need to do it on GPU, it's just 6 instances in array
    func compute(encoder: MTLComputeCommandEncoder) {
        encoder.setComputePipelineState(tessellationPipelineState)
        encoder.setBuffer(tessellationFactorBuffer, offset: 0, index: 0)
        // Bind additional resources as needed
        
        let threadgroupSize = MTLSize(width: tessellationPipelineState.threadExecutionWidth, height: 1, depth: 1)
        let threadCount = MTLSize(width: patchCount, height: 1, depth: 1)
        encoder.dispatchThreads(threadCount, threadsPerThreadgroup: threadgroupSize)
    }
    
    func render(
        encoder: MTLRenderCommandEncoder,
        viewProjectionMatrix: float4x4,
        camera: Camera,
        deltaTime: Double
    ) {
        guard let mesh, let materialState else {
            return
        }
        var uniforms = MeshUniforms(
            mvp: viewProjectionMatrix * model,
            model: model,
            view: camera.viewMatrix,
            normalModel: calculateNormalMatrix(model),
            time: Float(deltaTime)
        )
        
        // Set the pipeline state
        materialState.activate(encoder: encoder, camera: camera)

        // Set the vertex buffer and any required uniforms
        encoder.setVertexBuffer(mesh.vertexBuffer.buffer, offset: 0, index: 0)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<MeshUniforms>.stride, index: 3)
        encoder.setVertexBuffer(shapePathBuffer, offset: 0, index: 4)
        encoder.setVertexBuffer(cornerPathBuffer, offset: 0, index: 5)
        
        encoder.setTessellationFactorBuffer(tessellationFactorBuffer, offset: 0, instanceStride: 0)

        // Draw the mesh using the index buffer
        encoder.drawIndexedPatches(
            numberOfPatchControlPoints: controlPointsPerPatch, // 4 for quad
            patchStart: 0,
            patchCount: patchCount,
            patchIndexBuffer: nil,
            patchIndexBufferOffset: 0,
            controlPointIndexBuffer: mesh.indexBuffer.buffer,
            controlPointIndexBufferOffset: mesh.indexBuffer.offset,
            instanceCount: 1,
            baseInstance: 0
        )
    }
    
    // MARK: - Utils
    private func calculateScale(rect: CGRect) -> SIMD3<Float> {
        let frameSize = SIMD3(Float(rect.width), Float(rect.height), 50.0) // TODO:
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
