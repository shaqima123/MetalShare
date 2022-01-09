//
//  sigmentComputeShader.metal
//  MetalShare
//
//  Created by shaqima on 2022/1/3.
//

#include <metal_stdlib>
using namespace metal;

kernel void segmentCompute(
    texture2d<float, access::write> outputTexture [[texture(0)]],
    device int* segmentationMask [[buffer(0)]],
    uint2 grid [[thread_position_in_grid]]
) {
    if (grid.x >= outputTexture.get_width() || grid.y >= outputTexture.get_height()) {
        return;
    }

    const int segmentationWidth = 513;
    const int segmentationHeight = 513;

    float width = outputTexture.get_width();
    float height = outputTexture.get_height();

    const float2 pos = float2(float(grid.x) / width, float(grid.y) / height);

    const int x = int(pos.x * segmentationWidth);
    const int y = int(pos.y * segmentationHeight);
    const int label = segmentationMask[y * segmentationWidth + x];
    const bool isPerson = label == 15;

    float4 outPixel;

    if (isPerson) {
        outPixel = float4(1.0, 1.0, 1.0, 1.0);
    } else {
        outPixel = float4(0.0, 0.0, 0.0, 1.0);
    }

    outputTexture.write(outPixel, grid);
}

