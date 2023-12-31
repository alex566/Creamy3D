//
//  Header.h
//  
//
//  Created by Alexey Oleynik on 30.09.23.
//

#pragma once

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float3 tangent;
    float3 vNormal;
    float3 vTangent;
    float3 worldPos;
    float2 uv;
};
