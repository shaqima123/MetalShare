//
//  KiraMetalView.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/6/18.
//

import UIKit

class KiraMetalView: UIView {
    
    var metalLayer: CAMetalLayer {
        return layer as! CAMetalLayer
    }
    private var render: Renderer!
    private var verticesCount: Int!
    private var textureImage: UIImage?
    
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setup(verticesCount: Int, image: UIImage?) {
        self.verticesCount = verticesCount
        self.textureImage = image
        
        render = Renderer(metalLayer: metalLayer, verticesCount: verticesCount)
        render.setupBuffer()
        render.setupTexture(image: image)
        render.setupPipeline()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        render.render()
    }
    
}
