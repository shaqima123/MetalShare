//
//  Texture.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/6/24.
//

import Foundation
import MetalKit

public class Texture {
    public let texture: MTLTexture
    public init(texture: MTLTexture) {
        self.texture = texture
    }
    
    public init(pixelFormat: MTLPixelFormat = .bgra8Unorm, width: Int, height: Int, mipmapped: Bool = false) {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: mipmapped)
        //todo: study
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        
        guard let newTexture = sharedMetalHeartDevice.device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Could not create Texture of size:(\(width),\(height)")
        }
        
        self.texture = newTexture
    }
}
