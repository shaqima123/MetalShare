//
//  RenderView.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/7/10.
//

import Foundation
import MetalKit

public class RenderView: UIView {
    public let sources = SourceContainer()
    public let maximumInputs: UInt = 2
    
    public var clearColor = RenderColor.clearColor
    
    public var fillMode = FillMode.preserveAspectRatio
    
    var currentTexture: Texture?
    var renderPipelineState: MTLRenderPipelineState!
    // 是否使用 backup pipelineState
    var enableBackupPLS: Bool = false
    
    lazy var metalView: MTKView = {
        let metalView = MTKView.init(frame: self.bounds, device: sharedMetalHeartDevice.device)
        metalView.isPaused = true

        return metalView
    }()
    
    // MARK: -
    // MARK: Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        renderPipelineState = generateRenderPipelineState(vertexFunctionName: FunctionName.OneInputVertex,
                                                          fragmentFunctionName: FunctionName.PassthroughFragment)
        metalView.delegate = self
        addSubview(metalView)
    }
    
    func processPictureSources() {
        enableBackupPLS = true
        metalView.draw()
    }
    
    func renderSources(commandBuffer: MTLCommandBuffer!,
                       outputTexture:Texture,
                       clearColor: MTLClearColor = RenderColor.clearColor
    ) {
        let textureLoader = sharedMetalHeartDevice.textureLoader
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].clearColor = clearColor
        renderPassDescriptor.colorAttachments[0].texture = outputTexture.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        commandEncoder?.setFrontFacing(.counterClockwise)
        do {
            for sourceIndex in 0..<self.sources.sources.values.count {
                if let picture = self.sources.sources[UInt(sourceIndex)] as? PictureInput {
                    let imageTexture = try textureLoader.newTexture(cgImage: picture.internalImage!, options: [MTKTextureLoader.Option.SRGB : false])
                    let scaledVertices = picture.fillMode.transformVertices(imageVertices, fromInputSize:CGSize(width: imageTexture.width, height: imageTexture.height), toFitSize:metalView.drawableSize)
                    let vertexBuffer = sharedMetalHeartDevice.device.makeBuffer(bytes: scaledVertices,
                                                                                length: scaledVertices.count * MemoryLayout<Float>.size,
                                                                                options: [])!
                    vertexBuffer.label = "Vertices"
                    
                    if (picture.renderPipelineStateBackup != nil) {
                        commandEncoder?.setRenderPipelineState(picture.renderPipelineStateBackup)
                    } else {
                        commandEncoder?.setRenderPipelineState(renderPipelineState)
                    }
                    commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                    let textureBuffer = sharedMetalHeartDevice.device.makeBuffer(bytes: textureCoordinates, length: textureCoordinates.count * MemoryLayout<Float>.size, options: [])!
                    commandEncoder?.setVertexBuffer(textureBuffer, offset: 0, index: 1)
                    commandEncoder?.setFragmentTexture(imageTexture, index: 0)
                    commandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: scaledVertices.count / 2)
                    
                }
            }
            commandEncoder?.endEncoding()
        } catch {
            fatalError("Failed loading image texture")
        }
    }
}

// MARK: -
// MARK: ImageConsumer
extension RenderView: ImageConsumer {
    
    public func newTextureAvailable(_ texture: Texture, fromSourceIndex: UInt) {
        currentTexture = texture
        
        metalView.draw()
    }
}

// MARK: -
// MARK: MTKViewDelegate
extension RenderView: MTKViewDelegate {
    
    public func draw(in view: MTKView) {
        guard let currentDrawable = self.metalView.currentDrawable else {
                debugPrint("Warning: Could update Current Drawable")
                return
        }
        
        let commandBuffer = sharedMetalHeartDevice.commandQueue.makeCommandBuffer()!
        let outputTexture = Texture(texture: currentDrawable.texture)

        if enableBackupPLS {
            renderSources(commandBuffer: commandBuffer, outputTexture: outputTexture)
            //用完就关
            enableBackupPLS = false
        } else {
            guard let imageTexture = currentTexture else {
                debugPrint("Warning: currentTexture is nil")
                return
            }
            let scaledVertices = fillMode.transformVertices(imageVertices, fromInputSize:CGSize(width: imageTexture.texture.width, height: imageTexture.texture.height), toFitSize:metalView.drawableSize)

            commandBuffer.renderQuad(pipelineState: renderPipelineState, inputTextures: [0:imageTexture], outputTexture: outputTexture, clearColor:clearColor, imageVertices: scaledVertices)
        }
        
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
