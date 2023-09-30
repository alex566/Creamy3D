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
    
    float2 uv = inFrag.vNormal.xy * 0.5 + 0.5;
    float4 matcapColor = data->texture.sample(smp, float2(uv.x, 1.f - uv.y));
    return matcapColor;
}
