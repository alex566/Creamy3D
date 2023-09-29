//
//  waved_sphere.metal
//  Creamy3D
//
//  Created by Alexey Oleynik on 25.03.23.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Vertex {
     float4 position [[attribute(0)]];
     float3 normal [[attribute(1)]];
     float2 uv [[attribute(2)]];
};

struct VertexOut {
     float4 position [[position]];
     float3 normal;
     float3 vNormal;
     float3 worldPos;
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
    out.worldPos = (uniforms.model * pos).xyz;
    return out;
}

fragment float4 fragment_matcap(VertexOut inFrag [[stage_in]], texture2d<float> matcapTex [[texture(0)]]) {
     constexpr sampler smp(mag_filter::linear, min_filter::linear, mip_filter::linear, address::clamp_to_edge);

     float2 uv = inFrag.vNormal.xy * 0.5 + 0.5;
     float4 matcapColor = matcapTex.sample(smp, float2(uv.x, 1.f - uv.y));
     return matcapColor;
}
