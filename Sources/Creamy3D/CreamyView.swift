//
//  CreamyView.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 29.09.23.
//

import SwiftUI
import simd

public struct CameraPlacement {
    public let position: SIMD3<Float>
    public let target: SIMD3<Float>
    
    public static func from(_ position: SIMD3<Float>, lookAt: SIMD3<Float>) -> Self {
        .init(position: position, target: lookAt)
    }
    
    public func movingTo(_ newPosition: SIMD3<Float>) -> Self {
        .init(position: newPosition, target: target)
    }
}

public struct CreamyView: View {
    let cameraPlacement: CameraPlacement
    let objects: [any Object]
    
    public init(
        cameraPlacement: CameraPlacement = .from(.init(x: 0.0, y: 0.0, z: -1000.0), lookAt: .zero),
        @ObjectBuilder makeScene: () -> [any Object]
    ) {
        self.cameraPlacement = cameraPlacement
        self.objects = makeScene()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            MetalView(
                projection: .init(width: proxy.size.width,
                                  height: proxy.size.height,
                                  nearZ: 0.001,
                                  farZ: .greatestFiniteMagnitude),
                camera: .init(position: cameraPlacement.position,
                              target: cameraPlacement.target,
                              up: .init(x: 0.0, y: 1.0, z: 0.0)),
                objects: objects
            )
        }
    }
}
