//
//  AdjustFilter.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/9/12.
//


public class SaturationFilter: BasicOperation {
    public var saturation: Float = 1.0 {
        didSet {
            uniformSettings[0] = saturation
        }
    }
    
    public init() {
        super.init(fragmentFunctionName: "saturationFragment",numberOfInputs: 1)
        uniformSettings.appendUniform(1.0)
    }
}

public class BrightnessFilter: BasicOperation {
    public var brightness: Float = 1.0 {
        didSet {
            uniformSettings[0] = brightness;
        }
    }
    public init() {
        super.init(fragmentFunctionName: "brightnessFragment", numberOfInputs: 1)
        uniformSettings.appendUniform(1.0)
    }
}
