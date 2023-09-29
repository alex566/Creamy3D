//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 29.09.23.
//

import Foundation

public struct ColorMaterial: MeshMaterial {
    let color: ColorRGB
    
    public init(color: ColorRGB) {
        self.color = color
    }
}
