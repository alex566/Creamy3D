//
//  Renderer.swift
//  CelShading
//
//  Created by Alexey Oleynik on 04.03.23.
//

import MetalKit
import SwiftUI

final class Renderer: NSObject, ObservableObject {
    
    private static let buffersCount = 3
    
    // MARK: Metal
    public let device: MTLDevice
    public let library: MTLLibrary
    public let commandQueue: MTLCommandQueue
    
    // MARK: Resources
    private let meshAllocator: MTKMeshBufferAllocator
    private let textureLoader: MTKTextureLoader
    
    // MARK: Syncronization
    private let semaphore = DispatchSemaphore(value: Renderer.buffersCount)
    private var currentBuffer = 0
    private var frameIndex = 0
    
    // MARK: Scene
    private let startTime: TimeInterval
    
    private var viewMatrix = float4x4()
    private var projectionMatrix = float4x4()
    
    // MARK: - Mesh
    private var meshes = [String: MeshNode]()
    
    // MARK: - Init
    
    override init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create device")
        }
        guard let library = try? device.makeDefaultLibrary(bundle: Bundle.module) else {
            fatalError("Failed to create a library")
        }
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create a command queue")
        }
        
        self.device = device
        self.library = library
        self.commandQueue = commandQueue
        self.meshAllocator = MTKMeshBufferAllocator(device: device)
        self.textureLoader = MTKTextureLoader(device: device)
        
        self.startTime = Date().timeIntervalSince1970
        
        super.init()
    }
    
    func setup(view: MTKView) {
        view.delegate = self
        view.device = device
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.framebufferOnly = true
        view.clearDepth = 1.0
        view.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        view.depthStencilPixelFormat = .depth32Float
        view.backgroundColor = .clear
        view.drawableSize = CGSize(width: view.frame.width * 2.0, height: view.frame.height * 2.0)
    }
    
    func update(camera: Camera, projection: Projection) {
        self.viewMatrix = camera.makeMatrix()
        self.projectionMatrix = projection.makeMatrix()
    }
    
    func update(objects: [any Object], projection: Projection) {
        for object in objects {
            if let mesh = object as? Mesh {
                self.update(mesh: mesh, projection: projection)
            }
        }
    }
    
    // MARK: - Utils
    
    private func update(mesh: Mesh, projection: Projection) {
        if let node = meshes[mesh.id] {
            node.update(
                mesh: mesh, 
                projection: projection
            )
        } else {
            do {
                let node = MeshNode()
                try node.setup(
                    mesh: mesh,
                    allocator: meshAllocator,
                    textureLoader: textureLoader,
                    device: device,
                    library: library
                )
                node.update(
                    mesh: mesh,
                    projection: projection
                )
                meshes[mesh.id] = node
            } catch {
                print("Failed to add mesh(\(mesh.id): \(error)")
            }
        }
    }
}

extension Renderer: MTKViewDelegate {

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("Resize: \(size)")
    }

    public func draw(in view: MTKView) {
        semaphore.wait()
        
        autoreleasepool {
            executePasses(view: view) {
                self.semaphore.signal()
            }
        }
    }
    
    private func executePasses(view: MTKView, completion: @escaping () -> Void) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        guard let drawable = view.currentDrawable else {
            return
        }
        guard let descriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        // Encode all meshes
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)
        
        meshes.values.forEach { mesh in
            mesh.render(encoder: encoder,
                        viewProjectionMatrix: projectionMatrix * viewMatrix,
                        viewMatrix: viewMatrix,
                        deltaTime: startTime - Date().timeIntervalSince1970)
        }
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
                
        // Finalize
        commandBuffer.addCompletedHandler { _ in
            completion()
        }
        commandBuffer.commit()
        
        currentBuffer = (currentBuffer + 1) % Self.buffersCount
        frameIndex = (frameIndex + 1) % 64
    }
}
