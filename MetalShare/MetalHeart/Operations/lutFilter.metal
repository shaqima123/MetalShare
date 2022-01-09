//
//  lutFilter.metal
//  MetalShare
//
//  Created by shaoqianming on 2021/6/20.
//

#include <metal_stdlib>
#import "ShaderType.h"

using namespace metal;

typedef struct
{
    float intensity;
} IntensityUniform;


//片元着色器
fragment half4 lookupFragmentShader(TwoInputVertexIO inVertex [[stage_in]],
                                     texture2d<half> inputTexture[[texture(0)]],
                                     texture2d<half> inputTexture2 [[texture(1)]],
                                     constant IntensityUniform& uniform [[buffer(1)]])
{
  constexpr sampler quadSampler;
  half4 base = inputTexture.sample(quadSampler, inVertex.textureCoordinate);
  //B通道对应LUT上的数值
  half blueColor = base.b * 63.0h;
   
  // 计算临近两个B通道所在的方形LUT单元格（从左到右从上到下排列）
  half2 quad1;
  quad1.y = floor(floor(blueColor) / 8.0h);
  quad1.x = floor(blueColor) - (quad1.y * 8.0h);
   
  half2 quad2;
  quad2.y = floor(ceil(blueColor) / 8.0h);
  quad2.x = ceil(blueColor) - (quad2.y * 8.0h);
   
  // 单位像素上的中心偏移量
  float px_length = 1.0 / 512.0;
  float cell_length = 1.0 / 8;
    
  float2 texPos1;
  texPos1.x = (quad1.x * cell_length) + px_length / 2.0 + ((cell_length - px_length) * base.r);
  texPos1.y = (quad1.y * cell_length) + px_length / 2.0 + ((cell_length - px_length) * base.g);
   
  float2 texPos2;
  texPos2.x = (quad2.x * cell_length) + px_length/2.0 + ((cell_length - px_length) * base.r);
  texPos2.y = (quad2.y * cell_length) + px_length/2.0 + ((cell_length - px_length) * base.g);
   
  constexpr sampler quadSampler3;
  half4 newColor1 = inputTexture2.sample(quadSampler3, texPos1);
  constexpr sampler quadSampler4;
  half4 newColor2 = inputTexture2.sample(quadSampler4, texPos2);
   
  half4 newColor = mix(newColor1, newColor2, fract(blueColor));
  return half4(mix(base, half4(newColor.rgb, base.w), half(uniform.intensity)));
}
