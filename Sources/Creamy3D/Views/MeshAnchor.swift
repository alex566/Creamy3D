//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 18.08.24.
//

import SwiftUI

struct MeshAnchorKey: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(
        value: inout [String: Anchor<CGRect>],
        nextValue: () -> [String: Anchor<CGRect>]
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
        Color.clear
            .anchorPreference(key: MeshAnchorKey.self, value: .bounds) {
                anchor in
                [id: anchor]
            }
    }
}
