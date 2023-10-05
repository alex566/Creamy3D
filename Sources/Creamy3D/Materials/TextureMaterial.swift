//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 05.10.23.
//

import Foundation

public struct TextureMaterial: MeshMaterial {
    let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func makeFunction() -> MaterialFunction {
        TextureMaterialFunction(textureName: name)
    }
}
