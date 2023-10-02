//
//  matcap_material.metal
//  Creamy3D
//
//  Created by Alexey Oleynik on 25.03.23.
//

#include <metal_stdlib>
#include <simd/simd.h>

#include "material_common.h"

using namespace metal;

struct FresnelMaterialArgument {
    float3 color;
    float intensity;
};

float FresnelTerm(float cosTheta, float3 f0, float fresnelPower) {
    float schlickTerm = dot(f0, pow(1.0 - cosTheta, fresnelPower));
    return schlickTerm;
}

[[visible]]
float4 fresnel_material(VertexOut inFrag, device FresnelMaterialArgument *data) {
    float3 cameraPosition = float3(0.0, 0.f, -1000.f);
    float3 N = normalize(inFrag.normal);
    float3 V = normalize(cameraPosition - inFrag.worldPos);
    
    float3 f0 = 0.04;
    float3 fresnelColor = data->color;
    float cosPhi = dot(N, V);
    return float4(fresnelColor, FresnelTerm(cosPhi, f0, data->intensity));
}
