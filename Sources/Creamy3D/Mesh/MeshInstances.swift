//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 18.08.24.
//

import Foundation

public struct MeshInstances<Data: RandomAccessCollection> {
    let meshes: [Mesh]
    
    public init(_ data: Data, content: (Data.Element) -> Mesh) {
        self.meshes = data.map(content)
    }
}
