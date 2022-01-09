//
//  adjustFilter.metal
//  MetalShare
//
//  Created by shaoqianming on 2021/9/12.
//

#include <metal_stdlib>
#import "ShaderType.h"

using namespace metal;

typedef struct {
    float saturation;
    
} SaturationUniform;

typedef struct {
    float brightness;
} BrightnessUniform;

fragment half4 saturationFragment (SingleInputVertexIO input [[stage_in]],
                                   texture2d<half> texture [[texture(0)]],
                                   constant SaturationUniform& uniform [[buffer(1)]]
                                   ) {
    constexpr sampler quadSampler;
    half4 color = texture.sample(quadSampler, input.textureCoordinate);
    half gray = dot(color.rgb, grayWeight);
    return half4(mix(half3(gray), color.rgb, half(uniform.saturation)), color.a);
}

fragment half4 brightnessFragment (SingleInputVertexIO input [[stage_in]],
                                   texture2d<half> texture [[texture(0)]],
                                   constant BrightnessUniform& uniform [[buffer(1)]]
                                   ) {
    constexpr sampler quadSampler;
    half4 color = texture.sample(quadSampler, input.textureCoordinate);
    return half4(color.rgb + uniform.brightness, color.a);
}
