//
//  ColorRGB.swift
//
//
//  Created by Alexey Oleynik on 29.09.23.
//

import Foundation

public struct ColorRGB {
    let r: Double
    let g: Double
    let b: Double
    let a: Double
    
    public func linearToSRGB() -> Self {
        .init(
            r: linearToSRGB(r),
            g: linearToSRGB(g),
            b: linearToSRGB(b),
            a: 1.0
        )
    }
    
    public func SRGBToLinear() -> Self {
        .init(
            r: sRGBToLinear(r),
            g: sRGBToLinear(g),
            b: sRGBToLinear(b),
            a: 1.0
        )
    }
    
    // MARK: - Factories
    
    public static var black: Self {
        .init(r: 0.0, g: 0.0, b: 0.0, a: 1.0)
    }
    
    public static var white: Self {
        .init(r: 1.0, g: 1.0, b: 1.0, a: 1.0)
    }
    
    // MARK: - Utils
    
    private func linearToSRGB(_ linearValue: Double) -> Double {
        if linearValue <= 0.0031308 {
            return 12.92 * linearValue
        } else {
            return 1.055 * pow(linearValue, 1.0/2.4) - 0.055
        }
    }

    private func sRGBToLinear(_ sRGBValue: Double) -> Double {
        if sRGBValue <= 0.04045 {
            return sRGBValue / 12.92
        } else {
            return pow((sRGBValue + 0.055) / 1.055, 2.4)
        }
    }
}
