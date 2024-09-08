//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 02.09.24.
//

import Foundation

public struct NormalMaterial: MeshMaterial {
    
    public init() {
    }
    
    public func makeFunction() -> any MaterialFunction {
        NormalMaterialFunction()
    }
}
