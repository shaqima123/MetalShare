//
//  MetalHeartDevice.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/6/24.
//

import Foundation
import MetalKit

public let sharedMetalHeartDevice = MetalHeartDevice()

public class MetalHeartDevice {
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let shaderLibrary: MTLLibrary
    
    public let textureLoader: MTKTextureLoader
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Could not create Metal device")
        }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Cound not create command queue")
        }
        self.commandQueue = commandQueue
        
        do {
            let frameworkBundle = Bundle(for: MetalHeartDevice.self)
            let metalLibraryPath = frameworkBundle.path(forResource: "default", ofType: "metallib")!
            self.shaderLibrary = try device.makeLibrary(filepath: metalLibraryPath)
        } catch {
            fatalError("Could not load library")
        }
        
        self.textureLoader = MTKTextureLoader(device: self.device)
    }
}

