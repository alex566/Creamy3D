//
//  File.swift
//  Creamy3D
//
//  Created by Alexey Oleynik on 29.08.24.
//

import simd
import SwiftUI

enum ShapeSegmentType: Int {
    case line, curve
}

struct ShapePath {
    var segments: [ShapeSegment]
    
    init(path: Path) {
        var segments = [ShapeSegment]()
        
        var currentPoint = SIMD2<Float>(0, 0)
        path.forEach { element in
            switch element {
            case .move(let to):
                currentPoint = SIMD2<Float>(x: Float(to.x), y: Float(to.y))
            case .line(let to):
                let nextPoint = SIMD2<Float>(x: Float(to.x), y: Float(to.y))
                segments.append(
                    ShapeSegment(
                        from: currentPoint,
                        to: nextPoint,
                        controlPoint1: .zero,
                        controlPoint2: .zero,
                        tStart: 0.0,
                        tEnd: 0.0,
                        type: ShapeSegmentType.line.rawValue
                    )
                )
                currentPoint = nextPoint
            case .quadCurve(let to, let control):
                let nextPoint = SIMD2<Float>(x: Float(to.x), y: Float(to.y))
                let controlPoint1 = SIMD2<Float>(x: Float(control.x), y: Float(control.y))
                let controlPoint2 = SIMD2<Float>(x: Float(control.x), y: Float(control.y))
                
                segments.append(
                    ShapeSegment(
                        from: currentPoint,
                        to: nextPoint,
                        controlPoint1: controlPoint1,
                        controlPoint2: controlPoint2,
                        tStart: 0.0,
                        tEnd: 0.0,
                        type: ShapeSegmentType.curve.rawValue
                    )
                )
                
                currentPoint = nextPoint
            case .curve(let to, let control1, let control2):
                let nextPoint = SIMD2<Float>(x: Float(to.x), y: Float(to.y))
                let controlPoint1 = SIMD2<Float>(x: Float(control1.x), y: Float(control1.y))
                let controlPoint2 = SIMD2<Float>(x: Float(control2.x), y: Float(control2.y))
                segments.append(
                    ShapeSegment(
                        from: currentPoint,
                        to: nextPoint,
                        controlPoint1: controlPoint1,
                        controlPoint2: controlPoint2,
                        tStart: 0.0,
                        tEnd: 0.0,
                        type: ShapeSegmentType.curve.rawValue
                    )
                )
                currentPoint = nextPoint
            case .closeSubpath:
                guard let firstPoint = segments.first?.from else {
                    break
                }
                segments.append(
                    ShapeSegment(
                        from: currentPoint,
                        to: firstPoint,
                        controlPoint1: .zero,
                        controlPoint2: .zero,
                        tStart: 0.0,
                        tEnd: 0.0,
                        type: ShapeSegmentType.line.rawValue
                    )
                )
            }
        }
        self.segments = Self.calculateTime(segments: segments)
    }
    
    mutating func multiply(by vector: SIMD2<Float>) {
        for i in segments.indices {
            segments[i].multiply(by: vector)
        }
    }
    
    static func calculateTime(segments: consuming [ShapeSegment]) -> [ShapeSegment] {
        let totalLength = segments.reduce(0.0) { result, segment in
            result + segment.calculateLength()
        }
        
        var currentLength = Float(0.0)
        return segments.map { segment in
            var segment = segment
            let length = segment.calculateLength()
            segment.tStart = currentLength / totalLength
            segment.tEnd = (currentLength + length) / totalLength
            currentLength += length
            return segment
        }
    }
    
    // A function that accepts an array of integers and returns a filtered array of values < 10
    
}

struct ShapeSegment: CustomStringConvertible {
    var from: SIMD2<Float>
    var to: SIMD2<Float>
    var controlPoint1: SIMD2<Float>
    var controlPoint2: SIMD2<Float>
    var tStart: Float
    var tEnd: Float
    let type: Int
    
    mutating func multiply(by vector: SIMD2<Float>) {
        from *= vector
        to *= vector
        controlPoint1 *= vector
        controlPoint2 *= vector
    }
    
    func calculateLength() -> Float {
        switch type {
        case ShapeSegmentType.line.rawValue:
            return calculateLineLength()
        case ShapeSegmentType.curve.rawValue:
            return calculateCurveLength()
        default:
            fatalError("Unknown segment type")
        }
    }
    
    func calculateLineLength() -> Float {
        1.0 // No need to put too much positions for the line of any length
    }
        
    func calculateCurveLength(samples: Float = 41.0) -> Float {
        var length: Float = 0
        var lastPoint = from
        for i in stride(from: 1.0, through: samples, by: 4.0) {
            let t1 = i / samples
            let t2 = (i + 1) / samples
            let t3 = (i + 2) / samples
            let t4 = (i + 3) / samples
            
            let pointsFrom = SIMD8<Float>(from.x, from.y, from.x, from.y, from.x, from.y, from.x, from.y)
            let pointsTo = SIMD8<Float>(to.x, to.y, to.x, to.y, to.x, to.y, to.x, to.y)
            let controlPoints1 = SIMD8<Float>(controlPoint1.x, controlPoint1.y, controlPoint1.x, controlPoint1.y, controlPoint1.x, controlPoint1.y, controlPoint1.x, controlPoint1.y)
            let controlPoints2 = SIMD8<Float>(controlPoint2.x, controlPoint2.y, controlPoint2.x, controlPoint2.y, controlPoint2.x, controlPoint2.y, controlPoint2.x, controlPoint2.y)
            let ts = SIMD8<Float>(t1, t1, t2, t2, t3, t3, t4, t4)
            let a = simd_mix(pointsFrom, controlPoints1, ts)
            let b = simd_mix(controlPoints2, pointsTo, ts)
            let points = simd_mix(a, b, ts)
            
            let p1 = SIMD2(points[0], points[1])
            let p2 = SIMD2(points[2], points[3])
            let p3 = SIMD2(points[4], points[5])
            let p4 = SIMD2(points[6], points[7])
            
            let l1 = simd_fast_length(p1 - lastPoint)
            let l2 = simd_fast_length(p2 - p1)
            let l3 = simd_fast_length(p3 - p2)
            let l4 = simd_fast_length(p4 - p3)
            
            length += l1 + l2 + l3 + l4
            lastPoint = p4
        }
        return length
    }
    
    var description: String {
        switch type {
        case ShapeSegmentType.line.rawValue:
            return "Line from [\(tStart)...\(tEnd)] - \(Int((tEnd - tStart) * 100))%"
        case ShapeSegmentType.curve.rawValue:
            return "Curve from [\(tStart)...\(tEnd)] - \(Int((tEnd - tStart) * 100))%"
        default:
            fatalError("Unknown segment type")
        }
    }
}
