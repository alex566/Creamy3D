//
//  File.metal
//  Creamy3D
//
//  Created by Alexey Oleynik on 22.08.24.
//

#include <metal_stdlib>
using namespace metal;

constant half defaultEdgeFactor = 10.0;
constant half defaultInsideFactor = 10.0;

constant half edgeFactor[] = {
    defaultEdgeFactor, defaultEdgeFactor, defaultEdgeFactor, defaultEdgeFactor,
    10.0, 10.0
};

constant half insideFactor[] = {
    defaultInsideFactor, defaultInsideFactor, defaultInsideFactor, defaultInsideFactor,
    10.0, 10.0
};

kernel void compute_tess_factors(device MTLQuadTessellationFactorsHalf *factorsArray [[buffer(0)]],
                                 uint patchIndex [[thread_position_in_grid]]) {
    device MTLQuadTessellationFactorsHalf &patchFactors = factorsArray[patchIndex];
    patchFactors.edgeTessellationFactor[0] = edgeFactor[patchIndex];
    patchFactors.edgeTessellationFactor[1] = edgeFactor[patchIndex];
    patchFactors.edgeTessellationFactor[2] = edgeFactor[patchIndex];
    patchFactors.edgeTessellationFactor[3] = edgeFactor[patchIndex];
    patchFactors.insideTessellationFactor[0] = insideFactor[patchIndex];
    patchFactors.insideTessellationFactor[1] = insideFactor[patchIndex];
}
