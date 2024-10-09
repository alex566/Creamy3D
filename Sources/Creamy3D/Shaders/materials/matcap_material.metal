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

struct MatcapMaterialArgument {
    texture2d<float> texture;
};

[[visible]]
float4 matcap_material(VertexOut inFrag,
                       device MatcapMaterialArgument *data,
                       constant FragmentUniforms &uniforms) {
    constexpr sampler smp(mag_filter::bicubic, min_filter::bicubic);
    
    float3 viewDir = normalize(-inFrag.viewPos);
    float3 x = normalize(float3(viewDir.z, 0.f, -viewDir.x));
    float3 y = cross(viewDir, x);
    float2 uv = float2(dot(x, inFrag.normal), dot(y, inFrag.normal)) * 0.495 + 0.5;
    
    float4 matcapColor = data->texture.sample(smp, uv);
    return matcapColor;
}
