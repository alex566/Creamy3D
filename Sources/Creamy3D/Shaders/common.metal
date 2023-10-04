//
//  common.metal
//  Creamy3D
//
//  Created by Alexey Oleynik on 25.03.23.
//

#include <metal_stdlib>
#include <simd/simd.h>

#include "material_common.h"

using namespace metal;

struct Vertex {
     float4 position [[attribute(0)]];
     float3 normal [[attribute(1)]];
     float3 tangent  [[attribute(2)]]; 
     float2 uv [[attribute(3)]];
};

struct Uniforms {
     float4x4 MVP;
     float4x4 model;
     float4x4 view;
     float3x3 normalMatrix;
     float time;
};

vertex VertexOut vertex_common(Vertex in [[stage_in]], constant Uniforms &uniforms [[buffer(3)]]) {

    float3 displacedPosition = in.position.xyz;
    float3 adjustedNormal = in.normal;
    float4 pos = float4(displacedPosition, 1.0);
     
    VertexOut out;
    out.position = uniforms.MVP * pos;
    out.normal = normalize(uniforms.normalMatrix * adjustedNormal);
    out.vNormal = normalize(uniforms.view * float4(uniforms.normalMatrix * adjustedNormal, 0.f)).xyz;
    out.vTangent = (uniforms.view * float4(uniforms.normalMatrix * in.tangent, 0.f)).xyz;
    out.worldPos = (uniforms.model * pos).xyz;
    return out;
}

// MARK: - Fragment

using MaterialFunction = float4(VertexOut, device void *);

constant unsigned int resourcesStride [[function_constant(0)]];
constant int materialsCount [[function_constant(1)]];

struct Material {
    int functionIndex;
    int resourceIndex;
    int blend;
    float alpha;
};

// Normal Blend
float4 normalBlend(float4 src, float4 dst) {
    return src * src.a + dst * (1.0 - src.a);
}

// Multiply Blend
float4 multiplyBlend(float4 src, float4 dst) {
    return src * dst;
}

// Screen Blend
float4 screenBlend(float4 src, float4 dst) {
    return 1.0 - (1.0 - src) * (1.0 - dst);
}

// Overlay Blend
float4 overlayBlend(float4 src, float4 dst) {
    float3 resultRGB;
    resultRGB = metal::select(
        2.0 * src.rgb * dst.rgb,
        1.0 - 2.0 * (1.0 - src.rgb) * (1.0 - dst.rgb),
        dst.rgb > 0.5
    );
    return float4(resultRGB, src.a + dst.a - src.a * dst.a);
}

fragment float4 fragment_common(VertexOut inFrag [[stage_in]],
                                visible_function_table<MaterialFunction> materialFunctions [[buffer(0)]],
                                device void *resources [[buffer(1)]],
                                device Material *materials [[buffer(2)]]) {
    float4 finalColor = float4(0.f, 0.f, 0.f, 1.f);
    
    for (int i = 0; i < materialsCount; ++i) {
        Material material = materials[i];
        MaterialFunction *materialFunction = materialFunctions[material.functionIndex];
        device void *resource = ((device char *)resources + resourcesStride * material.resourceIndex);
        
        [[function_groups("material")]] float4 materialColor = materialFunction(inFrag, resource);
        materialColor.a *= material.alpha;
        
        switch (material.blend) {
            case 0:
                finalColor = normalBlend(materialColor, finalColor);
                break;
            case 1:
                finalColor = multiplyBlend(materialColor, finalColor);
                break;
            case 2:
                finalColor = screenBlend(materialColor, finalColor);
                break;
            case 3:
                finalColor = overlayBlend(materialColor, finalColor);
                break;
        }
    }
    return finalColor;
}
