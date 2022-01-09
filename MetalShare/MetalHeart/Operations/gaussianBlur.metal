//
//  gaussianBlur.metal
//  MetalShare
//
//  Created by shaoqianming on 2021/11/11.
//

#include <metal_stdlib>
#import "ShaderType.h"
using namespace metal;



typedef struct {
    float blur;
    
} BlurUniform;


fragment float4 gaussianBlurFragment(SingleInputVertexIO input [[stage_in]],
                                     texture2d<float, access::sample> texture [[texture(0)]],
                                     constant BlurUniform& uniform [[buffer(1)]]) {
    //1/16
    half offset = uniform.blur * 0.0625h;
    
    constexpr sampler qsampler(coord::normalized,
                               address::clamp_to_edge);
    float2 uv = input.textureCoordinate;
    float3 sum = float3(0.0, 0.0, 0.0);
    
    
    sum += texture.sample(qsampler, float2(uv.x - offset, uv.y - offset)).rgb * 0.0947416;
    sum += texture.sample(qsampler, float2(uv.x, uv.y - offset)).rgb * 0.118318;
    sum += texture.sample(qsampler, float2(uv.x + offset, uv.y - offset)).rgb * 0.0947416;
    sum += texture.sample(qsampler, float2(uv.x - offset, uv.y)).rgb * 0.118318;

    sum += texture.sample(qsampler, uv).rgb * 0.2270270270;
    
    sum += texture.sample(qsampler, float2(uv.x + offset, uv.y)).rgb * 0.118318;
    sum += texture.sample(qsampler, float2(uv.x - offset, uv.y + offset)).rgb * 0.0947416;
    sum += texture.sample(qsampler, float2(uv.x, uv.y + offset)).rgb * 0.118318;
    sum += texture.sample(qsampler, float2(uv.x + offset, uv.y + offset)).rgb * 0.0947416;

    float4 adjusted;
    adjusted.rgb = sum;
    adjusted.a = 1;
    return adjusted;
}

