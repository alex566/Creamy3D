//
//  MetalView.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 04.03.23.
//

import MetalKit
import SwiftUI

struct MetalView: UIViewRepresentable {
    let projection: Projection
    let camera: Camera
    let objects: [any Object]
    
    @StateObject
    var renderer = Renderer()
    
    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        renderer.setup(view: view)
        renderer.update(camera: camera, projection: projection)
        renderer.update(objects: objects, projection: projection, view: view)
        return view
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        renderer.update(camera: camera, projection: projection)
        renderer.update(objects: objects, projection: projection, view: uiView)
    }
}
