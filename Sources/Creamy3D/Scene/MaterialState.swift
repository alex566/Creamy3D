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

private struct ShaderMaterial {
    var functionIndex: Int32
    var resourceIndex: Int32
    var blend: Int32
    var alpha: Float
}

final class MaterialState {
    
    private var pipelineState: MTLRenderPipelineState!
    private var depthPipelineState: MTLDepthStencilState!
    
    private var materialFunctions = [any MaterialFunction]()
    private var resourcesBuffer: MTLBuffer!
    private var materialsBuffer: MTLBuffer!
    private var mtlFunctions = [MTLFunction]()
    
    func setup(
        materials: [any MeshMaterial],
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
        
        var (stride, buffer) = makeResourcesBuffer(device: device, functions: materialFunctions)
        var materialsCount = Int32(materialFunctions.count)
        
        resourcesBuffer = buffer
        materialsBuffer = makeMaterialsBuffer(
            device: device,
            materials: zip(materials, materialFunctions).map { ($0, $1) }
        )
        
        let constants = MTLFunctionConstantValues()
        constants.setConstantValue(&stride, type: .uint, index: 0)
        constants.setConstantValue(&materialsCount, type: .int, index: 1)
        
        let vertexFunction = library.makeFunction(name: "vertex_common")
        let fragmentFunction = try! library.makeFunction(name: "fragment_common", constantValues: constants)

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = makeVertexDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true

        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha

        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
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
    
    func activate(encoder: MTLRenderCommandEncoder) {
        encoder.setDepthStencilState(depthPipelineState)
        encoder.setRenderPipelineState(pipelineState)
        
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

        
        encoder.setFragmentBuffer(resourcesBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(materialsBuffer, offset: 0, index: 2)
        
        for materialFunction in materialFunctions {
            materialFunction.useResources(encoder: encoder)
        }
    }
    
    // MARK: - Utils
    
    private func makeVertexDescriptor() -> MTLVertexDescriptor {
        // Create the vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Position attribute
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        // Normal attribute
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // UV attribute
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD4<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0

        // Create a single interleaved layout
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD4<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        return vertexDescriptor
    }
    
    private func makeResourcesBuffer(device: MTLDevice, functions: [any MaterialFunction]) -> (stride: UInt32, buffer: MTLBuffer) {
        var resourcesStride = 0
        for function in functions {
            if function.resourcesSize > resourcesStride {
                resourcesStride = function.resourcesSize
            }
        }
        
        let buffer = device.makeBuffer(
            length: resourcesStride * functions.count,
            options: .storageModeShared
        )!
        
        let pointer = buffer.contents()
        for (i, function) in functions.enumerated() {
            let advancedPointer = pointer.advanced(by: resourcesStride * i)
            function.assignResources(pointer: advancedPointer)
        }
        
        return (UInt32(resourcesStride), buffer)
    }
    
    private func makeMaterialsBuffer(
        device: MTLDevice,
        materials: [(material: any MeshMaterial, function: any MaterialFunction)]
    ) -> MTLBuffer {
        let buffer = device.makeBuffer(
            length: MemoryLayout<ShaderMaterial>.stride * materials.count,
            options: .storageModeShared
        )!
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
