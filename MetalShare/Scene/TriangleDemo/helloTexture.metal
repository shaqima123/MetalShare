//
//  helloTexture.metal
//  MetalShare
//
//  Created by shaoqianming on 2021/6/19.
//

#include <metal_stdlib>
#import "ShaderTypesDefine.h"

using namespace metal;

typedef struct {
    float4 position [[position]];
    float2 textureCoordinate;
} TextureVertexData;

//顶点着色器
vertex TextureVertexData textureVertexShader(const device TextureVertex* vertices [[buffer(0)]],
                               uint vid[[vertex_id]]) {
    TextureVertexData outVertex;
    outVertex.position = vector_float4(vertices[vid].position, 0.0, 1.0);
    outVertex.textureCoordinate = vertices[vid].textureCoordinate;
    
    return outVertex;
}


//片元着色器
fragment float4 textureFragmentShader(TextureVertexData inVertex [[stage_in]],
                               texture2d<float> inputTexture[[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    return float4(inputTexture.sample(textureSampler, inVertex.textureCoordinate));
}


