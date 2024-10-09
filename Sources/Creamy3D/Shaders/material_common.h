//
//  Header.h
//  
//
//  Created by Alexey Oleynik on 30.09.23.
//

#pragma once

#include <simd/simd.h>

using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float3 tangent;
//    float3 vNormal;
//    float3 vTangent;
    float3 worldPos;
    float3 viewPos;
    float2 uv;
};

struct Uniforms {
     float4x4 MVP;
     float4x4 model;
     float4x4 view;
     float3x3 normalMatrix;
     float time;
};

struct FragmentUniforms {
    float3 cameraWorldPos;
};
