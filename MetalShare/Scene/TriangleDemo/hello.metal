//
//  hello.metal
//  MetalShare
//
//  Created by shaoqianming on 2021/6/18.
//

#include <metal_stdlib>
#import "ShaderTypesDefine.h"

using namespace metal;

typedef struct {
    float4 position [[position]];
    float4 color;
} VertexData;

//顶点着色器
vertex VertexData vertexShader(const device Vertex* vertices [[buffer(0)]],
                               uint vid[[vertex_id]]) {
    VertexData outVertex;
    outVertex.position = vector_float4(vertices[vid].position, 0.0, 1.0);
    outVertex.color = vertices[vid].color;
    
    return outVertex;
}


//片元着色器
fragment float4 fragmentShader(VertexData inVertex [[stage_in]]) {
    return inVertex.color;
}


