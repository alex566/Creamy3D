//
//  CreamyView.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 29.09.23.
//

import SwiftUI
import simd
import Spatial

public struct CreamyView<Content: View>: View, @preconcurrency Animatable {
    var cameraPlacement: CameraRotation
    let content: Content
    let meshes: [Mesh]
    
    public var animatableData: CameraRotation {
        get { cameraPlacement }
        set { cameraPlacement = newValue }
    }

    public init(
        cameraPlacement: CameraRotation = .initial,
        @ViewBuilder content: () -> Content,
        @MeshBuilder meshes: () -> [Mesh]
    ) {
        self.cameraPlacement = cameraPlacement
        self.content = content()
        self.meshes = meshes()
    }

    public var body: some View {
        content
            .coordinateSpace(name: "creamy_scene")
            .rotation3DEffect(.radians(cameraPlacement.rotation.angle.radians),
                                  axis: (cameraPlacement.rotation.axis.x,
                                         cameraPlacement.rotation.axis.y,
                                         cameraPlacement.rotation.axis.z),
                              anchorZ: 0.0,
                              perspective: 0.0)
            .backgroundPreferenceValue(MeshAnchorKey.self) { frames in
                GeometryReader { proxy in
                    // Shift the camera to put zero into the top left corner
                    let offset = SIMD3<Float>(
                        -Float(proxy.size.width / 2.0),
                        -Float(proxy.size.height / 2.0),
                        0.0
                    )
                    MetalView(
                        projection: .init(
                            width: proxy.size.width,
                            height: proxy.size.height,
                            nearZ: 0.01,
                            farZ: 2000.0),
                        camera: .init(
                            position: cameraPlacement.position,
                            target: cameraPlacement.target,
                            up: cameraPlacement.up,
                            offset: offset
                        ),
                        meshes: meshes,
                        anchors: frames // anchor.mapValues { proxy[$0] }
                    )
                }
            }
    }
}
