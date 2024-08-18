//
//  CreamyView.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 29.09.23.
//

import SwiftUI
import simd
import Spatial

public struct CameraPlacement {
    public let position: SIMD3<Float>
    public let target: SIMD3<Float>

    public static var initial: Self {
        .init(
            position: .init(x: 0.0, y: 0.0, z: 1000.0),
            target: .zero
        )
    }
    
    public static func from(_ position: SIMD3<Float>, lookAt: SIMD3<Float>)
        -> Self
    {
        .init(position: position, target: lookAt)
    }

    public func movingTo(_ newPosition: SIMD3<Float>) -> Self {
        .init(position: newPosition, target: target)
    }
}

public struct CreamyView<Content: View>: View {
    let cameraPlacement: CameraPlacement
    let content: Content
    let meshes: [Mesh]

    public init(
        cameraPlacement: CameraPlacement = .initial,
        @ViewBuilder content: () -> Content,
        @MeshBuilder meshes: () -> [Mesh]
    ) {
        self.cameraPlacement = cameraPlacement
        self.content = content()
        self.meshes = meshes()
    }

    public var body: some View {
        content
            .backgroundPreferenceValue(MeshAnchorKey.self) { anchor in
                GeometryReader { proxy in
                    // Shift the camera to put zero into the top left corner
                    let offset = SIMD3<Float>(
                        Float(proxy.size.width / 2.0),
                        Float(proxy.size.height / 2.0), 0.0)
                    MetalView(
                        projection: .init(
                            width: proxy.size.width,
                            height: proxy.size.height,
                            nearZ: 0.001,
                            farZ: .greatestFiniteMagnitude),
                        camera: .init(
                            position: cameraPlacement.position + offset,
                            target: cameraPlacement.target + offset,
                            up: .init(x: 0.0, y: 1.0, z: 0.0)),
                        meshes: meshes,
                        anchors: anchor.mapValues { proxy[$0] }
                    )
                }
            }
    }
}
