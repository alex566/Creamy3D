//
//  ColorRGB.swift
//
//
//  Created by Alexey Oleynik on 29.09.23.
//

import Foundation

public struct ColorRGB {
    public let r: Double
    public let g: Double
    public let b: Double
    
    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    public init(grayscale: Double) {
        self.r = grayscale
        self.g = grayscale
        self.b = grayscale
    }
    
    public func linearToSRGB() -> Self {
        .init(
            r: Self.linearToSRGB(r),
            g: Self.linearToSRGB(g),
            b: Self.linearToSRGB(b)
        )
    }
    
    public func SRGBToLinear() -> Self {
        .init(
            r: Self.sRGBToLinear(r),
            g: Self.sRGBToLinear(g),
            b: Self.sRGBToLinear(b)
        )
    }
    
    // MARK: - Factories
    
    @inlinable
    public static var black: Self {
        .init(r: 0.0, g: 0.0, b: 0.0)
    }
    
    @inlinable
    public static var white: Self {
        .init(r: 1.0, g: 1.0, b: 1.0)
    }
    
    @inlinable
    public static var red: Self {
        .init(r: 1.0, g: 0.0, b: 0.0)
    }
    
    @inlinable
    public static var green: Self {
        .init(r: 0.0, g: 1.0, b: 0.0)
    }
    
    @inlinable
    public static var blue: Self {
        .init(r: 0.0, g: 0.0, b: 1.0)
    }
    
    // MARK: - Internal
    
    @inlinable
    var simd: SIMD3<Float> {
        .init(Float(r), Float(g), Float(b))
    }
    
    // MARK: - Utils
    
    public static func linearToSRGB(_ linearValue: Double) -> Double {
        if linearValue <= 0.0031308 {
            return 12.92 * linearValue
        } else {
            return 1.055 * pow(linearValue, 1.0/2.4) - 0.055
        }
    }

    public static func sRGBToLinear(_ sRGBValue: Double) -> Double {
        if sRGBValue <= 0.04045 {
            return sRGBValue / 12.92
        } else {
            return pow((sRGBValue + 0.055) / 1.055, 2.4)
        }
    }
}
