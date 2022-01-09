//
//  ShaderTypesDefine.m
//  MetalShare
//
//  Created by shaoqianming on 2021/6/18.
//

#include <simd/simd.h>

typedef struct
{
    vector_float2 position;
    vector_float4 color;
} Vertex;

typedef struct
{
    vector_float2 position;
    vector_float2 textureCoordinate;
} TextureVertex;
