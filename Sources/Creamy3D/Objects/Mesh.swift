//
//  Mesh.swift
//  MilkWaves
//
//  Created by Alexey Oleynik on 29.09.23.
//

import SwiftUI

public struct Mesh: Object {
    
    public enum Source {
        case sphere
        case cube
        case obj(String)
        case stl(String)
    }
    
    internal struct Options {
        var isResizable: Bool
        var aspectRatio: (CGFloat?, ContentMode)?
        var offset: CGSize
        var rotation: (Angle, SIMD3<Double>)
    }
    
    let source: Source
    let material: any MeshMaterial
    let options: Options
    
    public init(
        source: Source,
        @MeshMaterialBuilder makeMaterial: () -> some MeshMaterial
    ) {
        self.init(
            source: source,
            material: makeMaterial(),
            options: .init(
                isResizable: false,
                aspectRatio: nil, 
                offset: .zero, 
                rotation: (.zero, .zero)
            )
        )
    }
    
    internal init(
        source: Source,
        material: some MeshMaterial,
        options: Options
    ) {
        self.source = source
        self.options = options
        self.material = material
    }
    
    internal var id: String {
        switch source {
        case .sphere:
            return "sphere"
        case .cube:
            return "cube"
        case .obj(let name):
            return "obj_\(name)"
        case .stl(let name):
            return "stl_\(name)"
        }
    }
}

public extension Mesh {
    
    func resizable() -> Self {
        var options = self.options
        options.isResizable = true
        return .init(
            source: source,
            material: material, 
            options: options
        )
    }
    
    func aspectRatio(_ aspectRatio: CGFloat? = nil, contentMode: ContentMode) -> Self {
        var options = self.options
        options.aspectRatio = (aspectRatio, contentMode)
        return .init(
            source: source,
            material: material, 
            options: options
        )
    }
    
    @inlinable
    func scaledToFill() -> Self {
        aspectRatio(contentMode: .fill)
    }
    
    @inlinable
    func scaledToFit() -> Self {
        aspectRatio(contentMode: .fit)
    }
}

public extension Mesh {
    
    func offset(_ offset: CGSize) -> Self {
        var options = self.options
        options.offset = offset
        return .init(
            source: source,
            material: material, 
            options: options
        )
    }

    @inlinable 
    func offset(x: CGFloat = 0, y: CGFloat = 0) -> Mesh {
        offset(.init(width: x, height: y))
    }
}

public extension Mesh {
    
    func rotation(
        _ angle: Angle,
        axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    ) -> Mesh {
        var options = self.options
        options.rotation = (angle, .init(axis.x, axis.y, axis.z))
        return .init(
            source: source,
            material: material,
            options: options
        )
    }
}
