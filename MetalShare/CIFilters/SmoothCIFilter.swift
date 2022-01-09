//
//  SmoothCIFilter.swift
//  MetalShare
//
//  Created by shaqima on 2021/12/19.
//

import Foundation
import CoreImage
import CoreImage

class SmoothCIFilter: CIFilter {
    static var kernel:CIKernel?
    public var input:CIImage?
    
    override init() {
        super.init()
        guard SmoothCIFilter.kernel != nil else {
            let bundle = Bundle.init(for:SmoothCIFilter.self)
            let url = bundle.url(forResource: "Smooth", withExtension: "cikernel")
            guard let kernelString = try? String.init(contentsOf: url!, encoding: String.Encoding.utf8) else {
                fatalError("kernel string is nil")
            }
            let kernelArray = CIKernel.makeKernels(source: kernelString)
            SmoothCIFilter.kernel = kernelArray?.first
            return
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func outputImage() -> CIImage? {
        guard input != nil else {
            fatalError("input img is nil")
        }
        let result = SmoothCIFilter.kernel?.apply(extent: input!.extent, roiCallback: { index, rect in
            return rect
        }, arguments: [input as Any])
        return result
    }
}
