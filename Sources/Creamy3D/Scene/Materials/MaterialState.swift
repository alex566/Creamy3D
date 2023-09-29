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

final class MaterialState {
    
    private var pipelineState: MTLRenderPipelineState!
    private var depthPipelineState: MTLDepthStencilState!
    
    private var matcapTexture: MTLTexture!
    
    init(device: MTLDevice, library: MTLLibrary) {
        let vertexFunction = library.makeFunction(name: "vertex_common")
        let fragmentFunction = library.makeFunction(name: "fragment_matcap")
        
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
        
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD4<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0

        // Create a single interleaved layout
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD4<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        // Create the render pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
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
    
    func setup(meshMaterial: MatcapMaterial, textureLoader: MTKTextureLoader) throws {
        do {
            self.matcapTexture = try textureLoader.newTexture(
                name: meshMaterial.name,
                scaleFactor: 1.0,
                bundle: nil,
                options: [.SRGB: true]
            )
        } catch {
            throw MaterialError.failedToLoadTexture
        }
    }
    
    func activate(encoder: MTLRenderCommandEncoder) {
        encoder.setDepthStencilState(depthPipelineState)
        encoder.setRenderPipelineState(pipelineState)
        
        encoder.setFragmentTexture(matcapTexture, index: 0)
    }
}
