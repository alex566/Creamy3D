//
//  color_material.metal
//  Creamy3D
//
//  Created by Alexey Oleynik on 25.03.23.
//

#include <metal_stdlib>
#include <simd/simd.h>

#include "material_common.h"

using namespace metal;

struct ColorMaterialArguments {
    float3 color;
};

[[visible]]
float4 color_material(VertexOut inFrag, device ColorMaterialArguments *resource) {
    return float4(resource->color, 1.f);
}
