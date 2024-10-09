//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 18.08.24.
//

import SwiftUI

struct MeshAnchorKey: PreferenceKey {
    // Regularly it should be [String: Anchor<CGRect>]
    // Because of the issue with coordinate space this workaround is needed
    static let defaultValue: [String: CGRect?] = [:]
    static func reduce(
        value: inout [String: CGRect?],
        nextValue: () -> [String: CGRect?]
    ) {
        value.merge(nextValue()) { $1 }
    }
}

public struct MeshAnchor: View {
    let id: String

    public init(id: String) {
        self.id = id
    }

    public var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: MeshAnchorKey.self,
                    value: [id: proxy.frame(in: .named("creamy_scene"))]
                )
        }
    }
}
