//
//  Renderer.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/6/18.
//

import Foundation
import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue : MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var metalLayer: CAMetalLayer!
    var vertexBuffer: MTLBuffer!
    var verticesCount: Int!
    var texture: MTLTexture!
    
    // MARK: - Life Circle
    init(metalLayer: CAMetalLayer){
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("GPU not available")
        }
        Renderer.device = device
        Renderer.commandQueue = commandQueue

        self.metalLayer = metalLayer
    }
    
    convenience init(metalLayer: CAMetalLayer, verticesCount: Int) {
        self.init(metalLayer: metalLayer)
        self.verticesCount = verticesCount
    }
    
    // MARK: - Pipeline
    
    func setupPipeline() {
        let library = Renderer.device?.makeDefaultLibrary()
 
        let vertexFunction = library?.makeFunction(name: (3 == verticesCount) ? "vertexShader": "textureVertexShader")
        let fragmentFunction = library?.makeFunction(name: (3 == verticesCount) ? "fragmentShader": "textureFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        
        pipelineState = try! Renderer.device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    // MARK: - Render
    
    func render() {
        guard let drawable = metalLayer.nextDrawable() else {
            return
        }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.48, 0.74, 0.92, 1)
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = Renderer.commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        commandEncoder?.setRenderPipelineState(pipelineState)
        
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setFragmentTexture(texture, index: 0)
        
        if verticesCount == 3 {
            commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesCount)
        } else {
            commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: verticesCount)
        }

        commandEncoder?.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    
    // MARK: - Buffer
    func setupBuffer() {
        if 3 == verticesCount {
            setupTriangleBuffer()
        } else {
            setupQuadrangleBuffer()
        }
    }
    
    
    func setupTriangleBuffer() {
        //定义三角形的顶点位置及颜色
        let vertices = [Vertex(position: [0.5, -0.5], color: [1, 0, 0, 1]),
                        Vertex(position: [-0.5, -0.5], color: [0, 1, 0, 1]),
                        Vertex(position: [0.0, 0.5], color: [0, 0, 1, 1])]
        
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.size * vertices.count, options: .cpuCacheModeWriteCombined)
    }
    
    func setupQuadrangleBuffer() {
        let vertices = [TextureVertex(position: [-1.0, -1.0], textureCoordinate: [0,1]),
                        TextureVertex(position: [-1.0, 1.0], textureCoordinate: [0,0]),
                        TextureVertex(position: [1.0, -1.0], textureCoordinate: [1,1]),
                        TextureVertex(position: [1.0, 1.0], textureCoordinate: [1,0])]
  
        vertexBuffer = Renderer.device.makeBuffer(bytes: vertices, length: MemoryLayout<TextureVertex>.size * vertices.count, options: .cpuCacheModeWriteCombined)
    }
        
    
    // MARK: - Texture
    func setupTexture(image: UIImage?){
        guard let img = image else {
            return
        }
        texture = makeTextureDIY(image: img)
    }
    
    func makeTextureDIY(image: UIImage!) -> MTLTexture? {
        // image 解压缩
        let imageRef = (image?.cgImage)!
        let width = imageRef.width
        let height = imageRef.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.size)
        let bytePerPixel: Int = 4
        let bytePerRow: Int = bytePerPixel * width
        //颜色分量，每个像素中每个颜色占用的位空间
        let bytePerComponent: Int = 8
        
        //bitmapInfo: CGImageAlphaInfo.premultipliedLast 包含alpha，alpha 位于 RGBA 的最后一位
        // CGBitmapInfo.byteOrder32Big 字节顺序，MacOS 大端模式， iOS 小端模式
        let bitmapContext = CGContext(data: rawData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bytePerComponent,
                                      bytesPerRow: bytePerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        bitmapContext?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        
        let texture: MTLTexture? = Renderer.device.makeTexture(descriptor: textureDescriptor)
        let region: MTLRegion = MTLRegionMake2D(0, 0, width, height)
        texture?.replace(region: region, mipmapLevel: 0, withBytes: rawData!, bytesPerRow: bytePerRow)
        free(rawData)
        return texture
    }
    
    
    func makeTextureByLoader(image: UIImage!) -> MTLTexture? {
        guard let cgimage = image.cgImage else {
            fatalError("error in making texture")
        }
        let texture: MTLTexture?
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        
        let options = [MTKTextureLoader.Option.SRGB : false,
                       MTKTextureLoader.Option.textureUsage:
                        NSNumber(value: MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.renderTarget.rawValue)]
        do {
            texture = try textureLoader.newTexture(cgImage: cgimage, options: options)
        } catch  {
            fatalError("Failed loading image texture")
        }
        return texture
    }
    
}
