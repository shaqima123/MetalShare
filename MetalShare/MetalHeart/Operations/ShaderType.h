//
//  ShaderType.h
//  MetalShare
//
//  Created by shaoqianming on 2021/7/8.
//

#ifndef ShaderType_h
#define ShaderType_h
using namespace metal;

constant half3 grayWeight = half3(0.2125, 0.7154, 0.0721);

struct SingleInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

struct TwoInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
    float2 textureCoordinate2 [[user(texturecoord2)]];
};


#endif /* ShaderType_h */
