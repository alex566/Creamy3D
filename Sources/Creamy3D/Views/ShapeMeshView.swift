//
//  SwiftUIView.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 17.09.24.
//

import SwiftUI

struct ShapeMeshView<MeshShape: Shape>: View {
    
    enum BevelStyle {
        case arc(CGFloat)
    }
    
    let id: String
    let bevel: BevelStyle
    let shape: MeshShape
    let materials: [any MeshMaterial]
    
    init(id: String,
         bevel: BevelStyle,
         makeShape: () -> MeshShape,
         @MeshMaterialBuilder makeMaterials: () -> [any MeshMaterial]) {
        
        self.id = id
        self.bevel = bevel
        self.shape = makeShape()
        self.materials = makeMaterials()
    }
    
    var body: some View {
        Color.clear
    }
}
