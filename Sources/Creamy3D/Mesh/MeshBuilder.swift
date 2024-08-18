//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 18.08.24.
//

import Foundation

@resultBuilder
public enum MeshBuilder {
    
    public static func buildBlock(_ meshes: Mesh...) -> [Mesh] {
        meshes
    }
    
    public static func buildBlock(_ instances: MeshInstances<some RandomAccessCollection>) -> [Mesh] {
        instances.meshes
    }
}
