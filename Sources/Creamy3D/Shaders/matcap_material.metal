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

struct MatcapMaterialArgument {
    texture2d<float> texture;
};

[[visible]]
float4 matcap_material(VertexOut inFrag, device MatcapMaterialArgument *data) {
    constexpr sampler smp(mag_filter::linear, min_filter::linear, mip_filter::linear, address::clamp_to_edge);
    
    float3 bitangent = cross(inFrag.vNormal, inFrag.vTangent);
    float3x3 TBN = float3x3(inFrag.vTangent, bitangent, inFrag.vNormal);
    float3 N = normalize(TBN * inFrag.vNormal);
    
    float2 uv = float2(-N.x, N.y) * 0.5 + 0.5;
    float4 matcapColor = data->texture.sample(smp, uv);
    return matcapColor;
}
