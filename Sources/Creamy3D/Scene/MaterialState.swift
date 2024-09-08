//
//  File.swift
//
//
//  Created by Alexey Oleynik on 29.09.23.
//

import MetalKit
import simd

enum MaterialError: Error {
    case failedToLoadTexture
}

struct ShaderMaterial {
    var functionIndex: Int32
    var resourceIndex: Int32
    var blend: Int32
    var alpha: Float
}

struct FragmentUniforms {
    let cameraWorldPosition: SIMD3<Float>
}

final class MaterialState {
    
    // For debugging purposes
    private let drawAsWireframe = false
    
    private var pipelineState: MTLRenderPipelineState!
    private var depthPipelineState: MTLDepthStencilState!
    
    private var resourcesStride = 0
    private var materialFunctions = [any MaterialFunction]()
    private var resourcesBuffer: MTLBuffer!
    private var materialsBuffer: MTLBuffer!
    private var mtlFunctions = [MTLFunction]()
    
    func setup(
        materials: [any MeshMaterial],
        vertexDescriptor: MTLVertexDescriptor,
        tessellationIndexType: MTLTessellationControlPointIndexType,
        config: Renderer.Config,
        device: MTLDevice,
        library: MTLLibrary,
        textureLoader: MTKTextureLoader
    ) throws {
        materialFunctions = try materials.map { material in
            let function = material.makeFunction()
            
            if !mtlFunctions.contains(where: { $0.name == function.functionName }) {
                let mtlFunction = library.makeFunction(name: function.functionName)!
                mtlFunctions.append(mtlFunction)
            }
            
            try function.loadResources(textureLoader: textureLoader)
            return function
        }
        
        resourcesStride = calculateResourcesStride(functions: materialFunctions)
        if resourcesStride == 0 {
            resourcesStride = 1
        }
        resourcesBuffer = device.makeBuffer(
            length: resourcesStride * materialFunctions.count,
            options: .storageModeShared
        )!
        updateResourcesBuffer(
            resourcesBuffer,
            stride: resourcesStride,
            functions: materialFunctions
        )
        
        var materialsCount = Int32(materialFunctions.count)
        
        materialsBuffer = device.makeBuffer(
            length: MemoryLayout<ShaderMaterial>.stride * materials.count,
            options: .storageModeShared
        )!
        materialsBuffer = updateMaterialsBuffer(
            materialsBuffer,
            materials: zip(materials, materialFunctions).map { ($0, $1) }
        )
        
        let constants = MTLFunctionConstantValues()
        constants.setConstantValue(&resourcesStride, type: .uint, index: 0)
        constants.setConstantValue(&materialsCount, type: .int, index: 1)
        
        let vertexFunction = library.makeFunction(name: "vertex_common")
        let fragmentFunction = try! library.makeFunction(name: "fragment_common", constantValues: constants)

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = config.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.rasterSampleCount = config.sampleCount

        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha

        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = config.depthPixelFormat
        
        pipelineDescriptor.tessellationPartitionMode = .pow2
        pipelineDescriptor.tessellationFactorStepFunction = .perPatch
        pipelineDescriptor.tessellationControlPointIndexType = tessellationIndexType
        
        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = mtlFunctions
        linkedFunctions.groups = [
            "material": mtlFunctions
        ]
        
        pipelineDescriptor.fragmentLinkedFunctions = linkedFunctions
        
        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create present pass \(error)")
        }
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        
        self.depthPipelineState = device.makeDepthStencilState(descriptor: depthDescriptor)!
    }
    
    func update(materials: [any MeshMaterial]) {
        for (function, material) in zip(materialFunctions, materials) {
            function.update(to: material)
        }
        updateResourcesBuffer(
            resourcesBuffer,
            stride: resourcesStride,
            functions: materialFunctions
        )
    }
    
    func activate(encoder: MTLRenderCommandEncoder, camera: Camera) {
        encoder.setDepthStencilState(depthPipelineState)
        encoder.setRenderPipelineState(pipelineState)
        encoder.setTriangleFillMode(drawAsWireframe ? .lines : .fill)
        
        // Setup functions for every material
        let materialsTableDescriptor = MTLVisibleFunctionTableDescriptor()
        materialsTableDescriptor.functionCount = mtlFunctions.count

        let materialsTable = pipelineState.makeVisibleFunctionTable(descriptor: materialsTableDescriptor, stage: .fragment)!
        for (i, function) in mtlFunctions.enumerated() {
            let functionHandle = pipelineState.functionHandle(
                function: function,
                stage: .fragment
            )!
            materialsTable.setFunction(functionHandle, index: i)
        }
        
        encoder.setFragmentVisibleFunctionTable(materialsTable, bufferIndex: 0)

        var uniforms = FragmentUniforms(cameraWorldPosition: camera.position)
        
        encoder.setFragmentBuffer(resourcesBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(materialsBuffer, offset: 0, index: 2)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 3)
        
        for materialFunction in materialFunctions {
            materialFunction.useResources(encoder: encoder)
        }
    }
    
    // MARK: - Utils
    
    private func calculateResourcesStride(functions: [any MaterialFunction]) -> Int {
        var resourcesStride = 0
        for function in functions {
            if function.resourcesSize > resourcesStride {
                resourcesStride = function.resourcesSize
            }
        }
        return resourcesStride
    }
    
    private func updateResourcesBuffer(
        _ buffer: MTLBuffer,
        stride: Int,
        functions: [any MaterialFunction]
    ) {
        let pointer = buffer.contents()
        for (i, function) in functions.enumerated() {
            let advancedPointer = pointer.advanced(by: stride * i)
            function.assignResources(pointer: advancedPointer)
        }
    }
    
    private func updateMaterialsBuffer(
        _ buffer: MTLBuffer,
        materials: [(material: any MeshMaterial, function: any MaterialFunction)]
    ) -> MTLBuffer {
        buffer.label = "Materials"
        let pointer = buffer.contents()
        for (i, material) in materials.enumerated() {
            guard let index = mtlFunctions.firstIndex(where: { $0.name == material.function.functionName }) else {
                continue
            }
            let binded = pointer.advanced(by: MemoryLayout<ShaderMaterial>.stride * i)
                .bindMemory(to: ShaderMaterial.self, capacity: 1)
            binded.pointee.functionIndex = Int32(index)
            binded.pointee.resourceIndex = Int32(i)
            binded.pointee.blend = Int32(material.material.blend.index)
            binded.pointee.alpha = Float(material.material.alpha)
        }
        return buffer
    }
}

extension MeshMaterialBlend {
    
    var index: Int {
        switch self {
        case .normal:
            return 0
        case .multiply:
            return 1
        case .screen:
            return 2
        case .overlay:
            return 3
        }
    }
}
