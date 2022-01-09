//
//  Utils.swift
//  MetalShare
//
//  Created by shaqima on 2021/12/18.
//

import Foundation
import UIKit

extension UIImage {

    func toFitSizePixelBuffer(fitSize:CGSize) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(fitSize.width), Int(fitSize.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(fitSize.width), height: Int(fitSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: fitSize.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      draw(in: CGRect(x: 0, y: 0, width: fitSize.width, height: fitSize.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
    
    func reSizeImage(reSize: CGSize ) -> UIImage {
        UIGraphicsBeginImageContextWithOptions (reSize, false, UIScreen.main.scale);
        draw(in: CGRect(x:0, y:0, width:reSize.width, height:reSize.height))
        let reSizeImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return reSizeImage;
    }
}

extension CGImage {
    func toCIImage() -> CIImage {
        return CIImage.init(cgImage: self)
    }
}

extension CIImage {
    func toCGImage() -> CGImage {
        let ciContext = CIContext.init()
        let cgImage:CGImage = ciContext.createCGImage(self, from: self.extent)!
        return cgImage
    }
}

