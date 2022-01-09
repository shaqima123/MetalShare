//
//  LookupFilter.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/7/10.
//

public class LookupFilter: BasicOperation {
    public var intensity: Float = 1.0 {
        didSet {
            uniformSettings[0] = intensity
        }
    }
    
    public var lookupImage: PictureInput? {
        didSet {
            lookupImage?.addTarget(self, atTargetIndex:1)
            lookupImage?.processImage()
        }
    }
    
    public init() {
        super.init(fragmentFunctionName:"lookupFragmentShader", numberOfInputs:2)
        
        uniformSettings.appendUniform(1.0)
    }
}
