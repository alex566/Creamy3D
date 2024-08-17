//
//  Mesh.swift
// 
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
        var rotation: (angle: Angle, axis: SIMD3<Double>)
        var frame: (width: CGFloat?, height: CGFloat?)?
        var insets: EdgeInsets
        var shouldGenerateNormals: Bool
    }
    
    let source: Source
    let materials: [any MeshMaterial]
    let options: Options
    
    public init(
        source: Source,
        @MeshMaterialBuilder makeMaterials: () -> [any MeshMaterial]
    ) {
        self.init(
            source: source,
            materials: makeMaterials(),
            options: .init(
                isResizable: false,
                aspectRatio: nil, 
                offset: .zero, 
                rotation: (.zero, .zero),
                frame: nil, 
                insets: .init(),
                shouldGenerateNormals: false
            )
        )
    }
    
    internal init(
        source: Source,
        materials: [any MeshMaterial],
        options: Options
    ) {
        self.source = source
        self.options = options
        self.materials = materials
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
            materials: materials,
            options: options
        )
    }
    
    func aspectRatio(_ aspectRatio: CGFloat? = nil, contentMode: ContentMode) -> Self {
        var options = self.options
        options.aspectRatio = (aspectRatio, contentMode)
        return .init(
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
            source: source,
            materials: materials,
            options: options
        )
    }
}

public extension Mesh {
    
    func offset(_ offset: CGSize) -> Self {
        var options = self.options
        options.offset = offset
        return .init(
            source: source,
            materials: materials,
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
            materials: materials,
            options: options
        )
    }
}

public extension Mesh {
    
    func frame(
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) -> Mesh {
        var options = self.options
        options.frame = (width, height)
        return .init(
            source: source,
            materials: materials,
            options: options
        )
    }
    
    @available(*, deprecated, message: "Please pass one or more parameters.")
    func frame() -> Mesh {
        self
    }
}

public extension Mesh {
    
    func padding(_ insets: EdgeInsets) -> Mesh {
        var options = self.options
        options.insets = insets
        return .init(
            source: source,
            materials: materials,
            options: options
        )
    }
    
    func padding(_ edges: Edge.Set = .all, _ length: CGFloat = 16.0) -> Mesh {
        padding(insets(edges: edges, length: length))
    }
    
    @inlinable
    func padding(_ length: CGFloat = 16.0) -> Mesh {
        padding(.all, length)
    }
    
    private func insets(edges: Edge.Set, length: CGFloat) -> EdgeInsets {
        .init(
            top: edges.contains(.top) ? length : 0.0,
            leading: edges.contains(.leading) ? length : 0.0,
            bottom: edges.contains(.bottom) ? length : 0.0,
            trailing: edges.contains(.trailing) ? length : 0.0
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
