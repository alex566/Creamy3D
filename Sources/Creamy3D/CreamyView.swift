//
//  CreamyView.swift
//  MilkWaves
//
//  Created by Alexey Oleynik on 29.09.23.
//

import SwiftUI
import simd

public struct CreamyView<RootObject: Object>: View {
    let rootObject: RootObject
    
    public init(@ObjectBuilder makeScene: () -> RootObject) {
        self.rootObject = makeScene()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            MetalView(
                projection: .init(width: proxy.size.width,
                                  height: proxy.size.height,
                                  nearZ: 0.001,
                                  farZ: .greatestFiniteMagnitude),
                camera: .init(position: .init(x: 0.0, y: 0.0, z: -1000.0),
                              target: .zero,
                              up: .init(x: 0.0, y: 1.0, z: 0.0)),
                objects: [rootObject]
            )
        }
    }
}
