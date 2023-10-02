//
//  File.swift
//  
//
//  Created by Alexey Oleynik on 02.10.23.
//

import SwiftUI
import simd

extension Mesh {
    
    public var magnitudeSquared: Double {
        options.magnitudeSquared
    }
    
    public static var zero: Mesh {
        return Mesh(source: .sphere, materials: [], options: .zero)
    }

    public static func += (lhs: inout Mesh, rhs: Mesh) {
        lhs.options += rhs.options
    }

    public static func -= (lhs: inout Mesh, rhs: Mesh) {
        lhs.options -= rhs.options
    }

    public static func + (lhs: Mesh, rhs: Mesh) -> Mesh {
        Mesh(source: lhs.source, materials: lhs.materials, options: lhs.options + rhs.options)
    }

    public static func - (lhs: Mesh, rhs: Mesh) -> Mesh {
        Mesh(source: lhs.source, materials: lhs.materials, options: lhs.options - rhs.options)
    }

    public mutating func scale(by rhs: Double) {
        options.scale(by: rhs)
    }
    
    public static func == (lhs: Mesh, rhs: Mesh) -> Bool {
        lhs.id == rhs.id && lhs.options == rhs.options
    }
}

extension Mesh.Options: VectorArithmetic {
    
    static var zero: Self {
        .init(
            isResizable: false,
            aspectRatio: nil,
            offset: CGSize.zero,
            rotation: (angle: Angle(degrees: 0), axis: SIMD3<Double>(0, 0, 0)),
            frame: nil,
            insets: EdgeInsets()
        )
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isResizable == rhs.isResizable &&
        lhs.aspectRatio?.0 == rhs.aspectRatio?.0 && lhs.aspectRatio?.1 == rhs.aspectRatio?.1 &&
        lhs.offset == rhs.offset &&
        lhs.rotation.angle == rhs.rotation.angle && lhs.rotation.axis == rhs.rotation.axis &&
        lhs.frame?.width == rhs.frame?.width && lhs.frame?.height == rhs.frame?.height &&
        lhs.insets == rhs.insets
    }
    
    
    // MARK: - VectorArithmetic
    static func += (lhs: inout Self, rhs: Self) {
        lhs.offset.width += rhs.offset.width
        lhs.offset.height += rhs.offset.height
        lhs.rotation.angle += rhs.rotation.angle
        lhs.rotation.axis += rhs.rotation.axis
        lhs.insets.top += rhs.insets.top
        lhs.insets.bottom += rhs.insets.bottom
        lhs.insets.leading += rhs.insets.leading
        lhs.insets.trailing += rhs.insets.trailing
    }

    static func -= (lhs: inout Self, rhs: Self) {
        lhs.offset.width -= rhs.offset.width
        lhs.offset.height -= rhs.offset.height
        lhs.rotation.angle -= rhs.rotation.angle
        lhs.rotation.axis -= rhs.rotation.axis
        lhs.insets.top -= rhs.insets.top
        lhs.insets.bottom -= rhs.insets.bottom
        lhs.insets.leading -= rhs.insets.leading
        lhs.insets.trailing -= rhs.insets.trailing
    }
        
    static func + (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result += rhs
        return result
    }
        
    static func - (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result -= rhs
        return result
    }

    mutating func scale(by rhs: Double) {
        offset.width *= CGFloat(rhs)
        offset.height *= CGFloat(rhs)
        rotation.angle = Angle(degrees: rotation.angle.degrees * rhs)
        rotation.axis *= rhs
        insets.top *= CGFloat(rhs)
        insets.bottom *= CGFloat(rhs)
        insets.leading *= CGFloat(rhs)
        insets.trailing *= CGFloat(rhs)
    }
        
    var magnitudeSquared: Double {
        let offsetMagnitude = Double(offset.width * offset.width + offset.height * offset.height)
        let rotationMagnitude = rotation.angle.degrees * rotation.angle.degrees
        let axisMagnitude = length_squared(rotation.axis)
        let insetsMagnitude = Double(insets.top * insets.top + insets.bottom * insets.bottom + insets.leading * insets.leading + insets.trailing * insets.trailing)
        
        return offsetMagnitude + rotationMagnitude + axisMagnitude + insetsMagnitude
    }
}
