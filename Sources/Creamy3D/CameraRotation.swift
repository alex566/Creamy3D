//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 08.09.24.
//

import simd
import Spatial
import SwiftUICore

public struct CameraRotation: Sendable {
    var rotation: Rotation3D

    public static var initial: Self {
        .init(angle: .zero, axis: .zero)
    }
    
    public init(angle: Angle2D, axis: RotationAxis3D) {
        self.rotation = Rotation3D(angle: angle, axis: axis)
    }
    
    public init(rotation: Rotation3D) {
        self.rotation = rotation
    }
    
    var position: SIMD3<Float> {
        var initialPosition = Point3D(x: 0.0, y: 0.0, z: 1000.0)
        initialPosition.rotate(by: rotation)
        return SIMD3(Float(initialPosition.x), Float(initialPosition.y), Float(initialPosition.z))
    }
    
    var target: SIMD3<Float> {
        .zero
    }
    
    var up: SIMD3<Float> {
        var vector = Vector3D(x: 0.0, y: 1.0, z: 0.0)
        vector.rotate(by: rotation)
        return SIMD3(Float(vector.x), Float(vector.y), Float(vector.z))
    }
}

extension CameraRotation: AdditiveArithmetic {
    
    public static var zero: Self {
        .init(rotation: .init(simd_quatd(ix: 0.0, iy: 0.0, iz: 0.0, r: 0.0)))
    }
    
    public static func + (lhs: Self, rhs: Self) -> Self {
        .init(rotation: .init(lhs.rotation.quaternion + rhs.rotation.quaternion))
    }
    
    public static func - (lhs: Self, rhs: Self) -> Self {
        .init(rotation: .init(lhs.rotation.quaternion - rhs.rotation.quaternion))
    }
}

extension CameraRotation: VectorArithmetic {
    
    public mutating func scale(by rhs: Double) {
        rotation = .init(rotation.quaternion * rhs)
    }

    public var magnitudeSquared: Double {
        Double(simd_length_squared(rotation.vector))
    }
}
