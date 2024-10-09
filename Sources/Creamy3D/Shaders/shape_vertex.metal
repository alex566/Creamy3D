//
//  File.metal
//  Creamy3D
//
//  Created by Alexey Oleynik on 01.09.24.
//

#include <metal_stdlib>

using namespace metal;

#include "material_common.h"

struct ControlPoint {
    float4 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
    float3 tangent  [[attribute(2)]];
    float2 uv [[attribute(3)]];
};
 
struct PatchIn {
    patch_control_point<ControlPoint> controlPoints;
};

/// Calculate a value by bilinearly interpolating among four control points.
/// The four values c00, c01, c10, and c11 represent, respectively, the
/// upper-left, upper-right, lower-left, and lower-right points of a quad
/// that is parameterized by a normalized space that runs from (0, 0)
/// in the upper left to (1, 1) in the lower right (similar to Metal's texture
/// space). The vector `uv` contains the influence of the points along the
/// x and y axes.
template <typename T>
T bilerp(T c00, T c01, T c10, T c11, float2 uv) {
    T c0 = mix(c00, c01, T(uv[0]));
    T c1 = mix(c10, c11, T(uv[0]));
    return mix(c0, c1, T(uv[1]));
}

struct Segment {
    float2 from;
    float2 to;
    float2 controlPoint1;
    float2 controlPoint2;
    float tStart;
    float tEnd;
    int type;
};

float2 evaluateSegment(Segment segment, float t) {
    if (segment.type == 0) {
        // Line segment: interpolate between P0 and P1
        return mix(segment.from, segment.to, t);
    } else if (segment.type == 1) {
        // Bezier
        float2 a = mix(segment.from, segment.controlPoint1, t);
        float2 b = mix(segment.controlPoint2, segment.to, t);
        return mix(a, b, t);
    }
    return 0.f; // Fallback in case of an undefined type
}

float2 evaluateSegmentDerivative(Segment segment, float t) {
    if (segment.type == 1) {
        // Cubic Bézier derivative
        float2 P0 = segment.from;
        float2 P1 = segment.controlPoint1;
        float2 P2 = segment.controlPoint2;
        float2 P3 = segment.to;
        
        float u = 1.0 - t;
        
        float2 derivative =
            3.0 * u * u * (P1 - P0) +
            6.0 * u * t * (P2 - P1) +
            3.0 * t * t * (P3 - P2);
        
        return normalize(float2(derivative.y, -derivative.x));
    } else if (segment.type == 0) {
        float2 direction = normalize(segment.to - segment.from);
        return float2(direction.y, -direction.x);
    }
    
    return float2(0.0, 0.0); // Fallback for unsupported types
}

[[patch(quad, 4)]]
vertex VertexOut vertex_common(PatchIn patch [[stage_in]],
                               float2 positionInPatch [[position_in_patch]],
                               ushort patchId [[patch_id]],
                               constant Uniforms &uniforms [[buffer(3)]],
                               constant Segment *segments [[ buffer(4)]],
                               constant Segment &cornerSegment [[ buffer(5)]]) {

    float4 p00 = patch.controlPoints[0].position;
    float4 p01 = patch.controlPoints[1].position;
    float4 p10 = patch.controlPoints[3].position;
    float4 p11 = patch.controlPoints[2].position;
    
    float4 flatPosition = bilerp(p00, p01, p10, p11, positionInPatch);
    

    float2 uv = flatPosition.xy + 0.5f;
    
    float4 newPosition = flatPosition;
    float3 normal = patch.controlPoints[0].normal;
    float3 tangent = patch.controlPoints[0].tangent;
    
    float bevel = 16.f;
    bool isFront = patchId == 4;
    
    float t = 0.f;
    float distance = 1.f;
    
    switch (patchId) {
        case 0: // Right
            t = 0.25 + (1.f - positionInPatch.x) * 0.25;
            break;
        case 1: // Left
            t = 0.75 + (positionInPatch.x) * 0.25;
            break;
        case 2: // Bottom
            t = 0.5 + (1.f - positionInPatch.y) * 0.25;
            break;
        case 3: // Top
            t = positionInPatch.y * 0.25;
            break;
        case 4: // Front
        {
            // Calculate distance from each edge
            float topDist = 1.f - positionInPatch.x;
            float bottomDist = positionInPatch.x;
            
            float rightDist = 1.f - positionInPatch.y;
            float leftDist = positionInPatch.y;
            
            // Find the minimum distance to determine the closest edge
            if (topDist <= rightDist && topDist <= bottomDist && topDist <= leftDist) {
                // Closest to the top edge
                t = positionInPatch.y * 0.25;
                distance = 1.f - topDist * 2.f;
            } else if (rightDist <= topDist && rightDist <= bottomDist && rightDist <= leftDist) {
                // Closest to the right edge
                t = 0.25 + (1.f - positionInPatch.x) * 0.25;
                distance = 1.f - rightDist * 2.f;
            } else if (bottomDist <= topDist && bottomDist <= rightDist && bottomDist <= leftDist) {
                // Closest to the bottom edge
                t = 0.5 + (1.f - positionInPatch.y) * 0.25;
                distance = 1.f - bottomDist * 2.f;
            } else {
                // Closest to the left edge
                t = 0.75 + positionInPatch.x * 0.25;
                distance = 1.f - leftDist * 2.f;
            }
            break;
        }
        default:
            break;
    }

    for (int i = 0; i < 17; ++i) {
        if (t >= segments[i].tStart && t <= segments[i].tEnd) {
            // Normalize t within this segment
            float segmentT = (t - segments[i].tStart) / (segments[i].tEnd - segments[i].tStart);
            float2 curvePos = evaluateSegment(segments[i], segmentT);
            newPosition = float4(curvePos.x, curvePos.y, flatPosition.z, 1.f);
            normal = float3(evaluateSegmentDerivative(segments[i], segmentT), 0.f);

            if (isFront) {
                float4x4 mat = uniforms.model;
                float sx = length(float3(mat[0][0], mat[1][0], mat[2][0]));
                float sy = length(float3(mat[0][1], mat[1][1], mat[2][1]));
                
                // Move vertex closer to the edge to make it more detailed
                newPosition.xy *= float2(mix(1.f - bevel / sx, 1.f, distance),
                                         mix(1.f - bevel / sy, 1.f, distance));
                
    
                // Apply corner radius to Z axis
                float cornerT = 1.f - distance;
                float2 cornerPos = evaluateSegment(cornerSegment, cornerT);
                newPosition.z += cornerPos.x;
                
                // Calculate normal
                float3 normalForward = float3(0.f, 0.f, 1.f);
                normal = normalize(mix(normal, normalForward, cornerT));
            }
            break;
        }
    }
    
    VertexOut out;
    out.position = uniforms.MVP * newPosition;
    out.normal = normalize(uniforms.normalMatrix * normal);
    out.tangent = normalize(uniforms.normalMatrix * tangent);
    out.worldPos = (uniforms.model * newPosition).xyz;
    out.viewPos = (uniforms.view * float4(out.worldPos, 1.f)).xyz;
    out.uv = uv;
    return out;
}
