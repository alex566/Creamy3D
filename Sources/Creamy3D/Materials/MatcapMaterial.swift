//
//  MatcapMaterial.swift
//  MilkWaves
//
//  Created by Alexey Oleynik on 29.09.23.
//

import Foundation

public struct MatcapMaterial: MeshMaterial {
    let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    public func makeFunction() -> MaterialFunction {
        MatcapMaterialFunction(textureName: name)
    }
}
