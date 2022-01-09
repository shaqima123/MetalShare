//
//  sigmentFilter.metal
//  MetalShare
//
//  Created by shaqima on 2021/12/19.
//

#include <metal_stdlib>
#import "ShaderType.h"

using namespace metal;

typedef struct
{
    float alpha;
} SegmentUniform;

fragment half4 segmentFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                               texture2d<half> inputTexture [[texture(0)]],
                               texture2d<half> mask [[texture(1)]],
                               texture2d<half> material [[texture(2)]],
                               constant SegmentUniform& uniforms [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    constexpr sampler materialSampler(address::repeat);
    
    
    float2 inputSize = float2(inputTexture.get_width(), inputTexture.get_height());
    float2 materialSize = float2(material.get_width(), material.get_height());
    float2 materialCoord = inputSize / materialSize * fragmentInput.textureCoordinate;

    half4 baseColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    

    
    //1/16
    half offset = 0.03 * 0.0625h;
    
    constexpr sampler qsampler(coord::normalized,
                               address::clamp_to_edge);
    float2 uv = fragmentInput.textureCoordinate;
    half3 sum = half3(0.0, 0.0, 0.0);
    
    
    sum += mask.sample(qsampler, float2(uv.x - offset, uv.y - offset)).rgb * 0.0947416;
    sum += mask.sample(qsampler, float2(uv.x, uv.y - offset)).rgb * 0.118318;
    sum += mask.sample(qsampler, float2(uv.x + offset, uv.y - offset)).rgb * 0.0947416;
    sum += mask.sample(qsampler, float2(uv.x - offset, uv.y)).rgb * 0.118318;

    sum += mask.sample(qsampler, uv).rgb * 0.2270270270;
    
    sum += mask.sample(qsampler, float2(uv.x + offset, uv.y)).rgb * 0.118318;
    sum += mask.sample(qsampler, float2(uv.x - offset, uv.y + offset)).rgb * 0.0947416;
    sum += mask.sample(qsampler, float2(uv.x, uv.y + offset)).rgb * 0.118318;
    sum += mask.sample(qsampler, float2(uv.x + offset, uv.y + offset)).rgb * 0.0947416;

    half4 maskColor;
    maskColor.rgb = sum;
    maskColor.a = 1;
    
//    maskColor = mask.sample(quadSampler, fragmentInput.textureCoordinate);
    half4 materialColor = material.sample(materialSampler, materialCoord);
    return half4(mix(baseColor, materialColor, (1.0 - maskColor.r) * uniforms.alpha));
}


