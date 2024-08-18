//
//  Mesh.swift
// 
//
//  Created by Alexey Oleynik on 29.09.23.
//

import SwiftUI

public struct Mesh {
    
    public enum Source {
        case sphere
        case cube
        case obj(String)
        case stl(String)
    }
    
    internal struct Options {
        var aspectRatio: (CGFloat?, ContentMode)?
        var rotation: (angle: Angle, axis: SIMD3<Double>)
        var shouldGenerateNormals: Bool
    }
    
    let id: String
    let source: Source
    let materials: [any MeshMaterial]
    let options: Options
    
    public init(
        id: String,
        source: Source,
        @MeshMaterialBuilder makeMaterials: () -> [any MeshMaterial]
    ) {
        self.init(
            id: id,
            source: source,
            materials: makeMaterials(),
            options: .init(
                aspectRatio: nil,
                rotation: (.zero, .zero),
                shouldGenerateNormals: false
            )
        )
    }
    
    internal init(
        id: String,
        source: Source,
        materials: [any MeshMaterial],
        options: Options
    ) {
        self.id = id
        self.source = source
        self.options = options
        self.materials = materials
    }
}

public extension Mesh {
    
    func aspectRatio(_ aspectRatio: CGFloat? = nil, contentMode: ContentMode) -> Self {
        var options = self.options
        options.aspectRatio = (aspectRatio, contentMode)
        return .init(
            id: id,
            source: source,
            materials: materials,
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
    
    func generateNormals(_ shouldGenerate: Bool = true) -> Self {
        var options = self.options
        options.shouldGenerateNormals = shouldGenerate
        return .init(
            id: id,
            source: source,
            materials: materials,
            options: options
        )
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
            id: id,
            source: source,
            materials: materials,
            options: options
        )
    }
}

extension Mesh {
    
    func loader() -> any MeshLoader {
        switch source {
        case .sphere:
            return SphereMeshLoader(
                radii: .one,
                radialSegments: 100,
                verticalSegments: 100
            )
        case .cube:
            return CubeMeshLoader(
                dimensions: .one,
                segments: .one
            )
        case let .obj(name):
            return ModelMeshLoader(
                name: name,
                ext: "obj",
                shouldGenerateNormals: options.shouldGenerateNormals
            )
        case let .stl(name):
            return ModelMeshLoader(
                name: name,
                ext: "stl",
                shouldGenerateNormals: options.shouldGenerateNormals
            )
        }
    }
}
