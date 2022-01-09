//
//  MetalHeart.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/6/24.
//

import Foundation
import Metal
import CoreGraphics

extension MTLCommandBuffer {    
    func renderQuad(pipelineState: MTLRenderPipelineState,
                    uniformSettings:ShaderUniformSettings? = nil,
                    inputTextures:[UInt: Texture],
                    outputTexture:Texture,
                    clearColor: MTLClearColor = RenderColor.clearColor,
                    imageVertices: [Float] = imageVertices,
                    textureCoordinates: [Float] = textureCoordinates
                    ){
        let vertexBuffer = sharedMetalHeartDevice.device.makeBuffer(bytes: imageVertices,
                                                                    length: imageVertices.count * MemoryLayout<Float>.size,
                                                                    options: [])!
        vertexBuffer.label = "Vertices"

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].texture = outputTexture.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandEncoder = self.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        commandEncoder?.setFrontFacing(.counterClockwise)
        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        for textIndex in 0..<inputTextures.count {
            let currentTexture = inputTextures[UInt(textIndex)]!
            let textureBuffer = sharedMetalHeartDevice.device.makeBuffer(bytes: textureCoordinates, length: textureCoordinates.count * MemoryLayout<Float>.size, options: [])!
            commandEncoder?.setVertexBuffer(textureBuffer, offset: 0, index: 1 + textIndex)
            commandEncoder?.setFragmentTexture(currentTexture.texture, index: textIndex)
        }
        guard let encoder = commandEncoder else {
            fatalError("commandEncoder error")
        }
        uniformSettings?.restoreShaderSettings(renderEncoder: encoder)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: imageVertices.count / 2)
        encoder.endEncoding()

    }
}

func generateRenderPipelineState(vertexFunctionName: String, fragmentFunctionName: String) -> MTLRenderPipelineState {
    guard let vertexFunction = sharedMetalHeartDevice.shaderLibrary.makeFunction(name: vertexFunctionName) else {
        fatalError("Could not compile vertex function \(vertexFunctionName)")
    }
    
    guard let fragmentFunction = sharedMetalHeartDevice.shaderLibrary.makeFunction(name: fragmentFunctionName) else {
        fatalError("Could not compile fragment function \(fragmentFunctionName)")
    }
    
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    
    do {
        return try sharedMetalHeartDevice.device.makeRenderPipelineState(descriptor: descriptor)
    } catch {
        fatalError("Could not create render pipeline state for vertex:\(vertexFunctionName), fragment:\(fragmentFunctionName), error:\(error)")
    }
}

func generateRenderPipelineState(vertexFunctionName: String, fragmentFunctionName: String, pipelineDescriptorConfig: @escaping((_ descpriptor:MTLRenderPipelineDescriptor) -> ())) -> MTLRenderPipelineState {
    guard let vertexFunction = sharedMetalHeartDevice.shaderLibrary.makeFunction(name: vertexFunctionName) else {
        fatalError("Could not compile vertex function \(vertexFunctionName)")
    }
    
    guard let fragmentFunction = sharedMetalHeartDevice.shaderLibrary.makeFunction(name: fragmentFunctionName) else {
        fatalError("Could not compile fragment function \(fragmentFunctionName)")
    }
    
    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    pipelineDescriptorConfig(descriptor)
    
    do {
        return try sharedMetalHeartDevice.device.makeRenderPipelineState(descriptor: descriptor)
    } catch {
        fatalError("Could not create render pipeline state for vertex:\(vertexFunctionName), fragment:\(fragmentFunctionName), error:\(error)")
    }
}
