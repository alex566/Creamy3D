//
//  Renderer.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 04.03.23.
//

import MetalKit
import SwiftUI
import OSLog

@MainActor
final class Renderer: NSObject, ObservableObject {
    
    struct Config {
        let sampleCount: Int
        let colorPixelFormat: MTLPixelFormat
        let depthPixelFormat: MTLPixelFormat
    }
    
    private static let buffersCount = 3
    private let config: Config
    
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
        
        self.config = Self.makeConfig(device: device)
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
        view.colorPixelFormat = config.colorPixelFormat
        view.framebufferOnly = true
        view.clearDepth = 1.0
        view.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        view.depthStencilPixelFormat = config.depthPixelFormat
        view.backgroundColor = .clear
        view.sampleCount = config.sampleCount
    }
    
    func update(camera: Camera, projection: Projection) {
        self.viewMatrix = camera.makeMatrix()
        self.projectionMatrix = projection.makeMatrix()
    }
    
    func update(objects: [any Object], projection: Projection, view: MTKView) {
        let meshes = objects.compactMap { $0 as? Mesh }
        // Remove meshes that are not in the list anymore
        let allIDs = meshes.map { $0.id }
        self.meshes = self.meshes.filter { allIDs.contains($0.key) }
        // Update the rest
        meshes.forEach { mesh in
            self.update(mesh: mesh, projection: projection)
        }
        view.isPaused = false
    }
    
    // MARK: - Utils
    
    private func update(mesh: Mesh, projection: Projection) {
        if let node = meshes[mesh.id] {
            node.update(
                mesh: mesh,
                projection: projection
            )
            Logger.sceneLoading.debug("Updated node: \(mesh.id)")
        } else {
            do {
                let node = MeshNode()
                try node.setup(
                    mesh: mesh,
                    config: config,
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
                Logger.sceneLoading.debug("Added node: \(mesh.id)")
            } catch {
                Logger.sceneLoading.error("Failed to add mesh(\(mesh.id): \(error)")
            }
        }
    }
    
    private static func makeConfig(device: some MTLDevice) -> Config {
        let samples = [8, 4, 2]
        let sampleCount = samples.first { device.supportsTextureSampleCount($0) } ?? 1
        
        return .init(
            sampleCount: sampleCount,
            colorPixelFormat: .bgra8Unorm_srgb,
            depthPixelFormat: .depth32Float
        )
    }
}

extension Renderer: MTKViewDelegate {

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        Logger.sceneLoading.info("Scene resized to (\(size.width), \(size.height))")
    }

    public func draw(in view: MTKView) {
        semaphore.wait()
        
        autoreleasepool {
            executePasses(view: view) {
                self.semaphore.signal()
            }
        }
    }
    
    private func executePasses(view: MTKView, completion: @Sendable @escaping () -> Void) {
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
        commandBuffer.addCompletedHandler { @Sendable _ in
            completion()
        }
        commandBuffer.commit()
        
        currentBuffer = (currentBuffer + 1) % Self.buffersCount
        frameIndex = (frameIndex + 1) % 64
        
        view.isPaused = true
    }
}
