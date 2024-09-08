//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 27.08.24.
//

import SwiftUI

public struct ShapeMesh<S: Shape> {
    let id: String
    let materials: [any MeshMaterial]
    let options: Options
    let shape: S
    
    struct Options {
        var depth: CGFloat
    }
    
    public init(
        id: String,
        depth: CGFloat,
        makeShape: () -> S,
        @MeshMaterialBuilder materials: () -> [any MeshMaterial]
    ) {
        self.init(
            id: id,
            shape: makeShape(),
            materials: materials(),
            options: .init(
                depth: depth
            )
        )
    }
    
    init(
        id: String,
        shape: S,
        materials: [any MeshMaterial],
        options: Options
    ) {
        self.id = id
        self.shape = shape
        self.options = options
        self.materials = materials
    }
}
