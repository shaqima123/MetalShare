//
//  Computer.swift
//  MetalShare
//
//  Created by shaqima on 2022/1/3.
//

import Foundation
import Metal
import CoreGraphics

public class Computer {
    public class func compute(functionName: String,
                 size: CGSize,
                 inputBuffer: MTLBuffer,
                 outputTexture: Texture
                ) {
        guard let commandBuffer = sharedMetalHeartDevice.commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
                  fatalError("Failed to create Metal command buffer or encoder")
              }
        let function: MTLFunction? = sharedMetalHeartDevice.shaderLibrary.makeFunction(name: functionName)
        guard let fun = function, let computePipelineState = try? sharedMetalHeartDevice.device.makeComputePipelineState(function: fun) else {
            fatalError("computePipelineState create failed..")
        }
                
        commandEncoder.setComputePipelineState(computePipelineState)
        commandEncoder.setTexture(outputTexture.texture, index: 0)
        commandEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        
        let counts = MTLSizeMake(16, 16, 1)
        let groups = MTLSize(width: (Int(size.width) + counts.width - 1) / counts.width,
                             height: (Int(size.height) + counts.height - 1) / counts.height,
                             depth: 1)
        commandEncoder.dispatchThreadgroups(groups, threadsPerThreadgroup: counts)
//        let w = computePipelineState.threadExecutionWidth
//        let h = computePipelineState.maxTotalThreadsPerThreadgroup / w
//        let threadsPerThreadGroup = MTLSizeMake(w, h, 1)
//
//        let threadsPerGrid = MTLSizeMake(Int(size.width), Int(size.height), 1)
//
//        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        
    }
}
