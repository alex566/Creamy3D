//
//  matcap_material.metal
//  Creamy3D
//
//  Created by Alexey Oleynik on 25.03.23.
//

#include <metal_stdlib>
#include <simd/simd.h>

#include "../material_common.h"

using namespace metal;

struct FresnelMaterialArgument {
    float3 color;
    float intensity;
    float scale;
    float bias;
};

float FresnelTerm(float cosTheta, float3 f0, float fresnelPower) {
    return dot(f0, pow(1.0 - cosTheta, fresnelPower));
}

[[visible]]
float4 fresnel_material(VertexOut inFrag,
                        device FresnelMaterialArgument *data,
                        constant FragmentUniforms &uniforms) {
    float3 N = normalize(inFrag.vNormal);
    float3 V = normalize(uniforms.cameraWorldPos - inFrag.worldPos);
    
    float3 f0 = 0.04;
    float3 fresnelColor = data->color;
    float cosPhi = dot(N, V);
    float term = FresnelTerm(cosPhi, f0, data->intensity);
    return float4(fresnelColor, (data->bias + (1.f - data->bias) * term) * data->scale);
}
