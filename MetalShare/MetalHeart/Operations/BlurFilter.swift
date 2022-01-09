//
//  Blur.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/11/11.
//

import Foundation

public class GaussianBlurFilter: BasicOperation {
    public var blur: Float = 0.01 {
        didSet {
            uniformSettings[0] = blur
        }
    }
    
    public init() {
        super.init(fragmentFunctionName: "gaussianBlurFragment", numberOfInputs: 1)
        uniformSettings.appendUniform(1.0)
    }
}
