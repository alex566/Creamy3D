//
//  File.metal
//  Creamy3D
//
//  Created by Alexey Oleynik on 02.09.24.
//

#include <metal_stdlib>

#include "../material_common.h"

using namespace metal;

[[visible]]
float4 normal_material(VertexOut inFrag, device void *resource, constant FragmentUniforms &uniforms) {
    return float4((inFrag.vNormal + 1.f) * 0.5f, 1.f);
}
