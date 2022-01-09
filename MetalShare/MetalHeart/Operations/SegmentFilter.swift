//
//  SegmentFilter.swift
//  MetalShare
//
//  Created by shaqima on 2021/12/19.
//

import Foundation
public class SegmentFilter: BasicOperation {
    public var alpha: Float = 0.0 {
        didSet {
            uniformSettings[0] = alpha
        }
    }

    public var maskImage: PictureInput? {
        didSet {
            maskImage?.addTarget(self, atTargetIndex:1)
            maskImage?.processImage()
        }
    }

    public var materialImage: PictureInput? {
        didSet {
            materialImage?.addTarget(self, atTargetIndex:2)
            materialImage?.processImage()
        }
    }

    public init() {
        super.init(fragmentFunctionName:"segmentFragment", numberOfInputs:3)

        uniformSettings.appendUniform(0.0)
    }
}
