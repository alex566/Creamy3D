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

struct TextureMaterialArgument {
    texture2d<float> texture;
};

[[visible]]
float4 texture_material(VertexOut inFrag,
                        device TextureMaterialArgument *data,
                        constant FragmentUniforms &uniforms) {
    constexpr sampler smp(mag_filter::bicubic, min_filter::bicubic);
    
    float4 matcapColor = data->texture.sample(smp, inFrag.uv);
    return matcapColor;
}
