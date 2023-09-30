//
//  MaterialFunction.swift
//
//
//  Created by Alexey Oleynik on 30.09.23.
//

import Metal
import MetalKit

public enum MaterialFunctionError: Error {
    case failedToCreateFunction
    case failedToLoadResource
}

public protocol MaterialFunction {
    
    
    func loadResources(textureLoader: MTKTextureLoader) throws
    
    var resourcesSize: Int { get }
    func assignResources(pointer: UnsafeMutableRawPointer)
    func useResources(encoder: MTLRenderCommandEncoder)
    
    var functionName: String { get }
}
