//
//  MattingService.swift
//  MetalShare
//
//  Created by shaqima on 2021/12/18.
//

import Foundation
import UIKit
import CoreML

class MattingSerive: NSObject {
    private static let segmentationSize: CGSize = .init(width: 513, height: 513)
    private let context = CIContext()

    
    var model:DeepLabV3?
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
        let modelConfig = MLModelConfiguration()
        modelConfig.computeUnits = .cpuOnly
        guard let mdl = try? DeepLabV3(configuration: modelConfig) else {
            fatalError("DeepLabV3 init failed")
        }
        model = mdl
    }
    
    func handleImage(image: UIImage) -> CGImage? {
        let size:CGSize = CGSize(width: 513, height: 513)
        guard let buffer = image.toFitSizePixelBuffer(fitSize: size) else {
            return nil
        }
        guard let mdl = model, let output = try? mdl.prediction(image: buffer) else {
            return nil
        }
        let shape = output.semanticPredictions.shape
        let (w,h) = (Int(truncating: shape[0]),Int(truncating: shape[1]))
        
        let bytesPerComponent = MemoryLayout<UInt8>.size
        let bytesPerPixel = bytesPerComponent * 4
        let length = w * h * bytesPerPixel
        var data = Data(count: length)
        
        data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
            var pointer = bytes
            for i in 0..<w {
                for j in 0..<h {
                    let offset = i * w + j
                    let k = Int(truncating: output.semanticPredictions[offset])
                    let v:UInt8 = (k == 15) ? 255 : 0
                    for _ in 0...3 {
                        pointer.pointee = v
                        pointer += 1
                    }
                }
            }
        }
        
        let provider: CGDataProvider = CGDataProvider(data: data as CFData)!
        let cgimg = CGImage(
                width: w,
                height: h,
                bitsPerComponent: bytesPerComponent * 8,
                bitsPerPixel: bytesPerPixel * 8,
                bytesPerRow: bytesPerPixel * w,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: CGColorRenderingIntent.defaultIntent
            )
        return cgimg
    }
    
    func handleMaskImage(maskImg: CGImage) -> CGImage? {
        let ciImage = maskImg.toCIImage()
        let smoothFilter = SmoothCIFilter()
        smoothFilter.input = ciImage
        
        guard let result = smoothFilter.outputImage() else {
            return nil
        }
        return result.toCGImage()
    }
    
    func handleImageV2(image: UIImage) -> CIImage? {
        let size = image.size
        guard let buffer = image.toFitSizePixelBuffer(fitSize: size) else {
            return nil
        }
        guard let ciImage = try? handlePixelBuffer(pixelBuffer: buffer, size: size) else {
            fatalError("handle error")
        }
        return ciImage
    }
    
    func handlePixelBuffer(pixelBuffer:CVPixelBuffer, size: CGSize) throws -> CIImage? {
        
        let modelInput = createModelInput(pixelBuffer, size: size)
        
        guard let mdl = model, let output = try? mdl.prediction(image: modelInput) else {
            return nil
        }
        let maskBuffer = createMaskBuffer(modelOutput: output)
        let outputTexture = Texture(width: Int(size.width), height: Int(size.height))
        Computer.compute(functionName: "segmentCompute", size: size, inputBuffer: maskBuffer, outputTexture: outputTexture)
        let ciImage = renderTextureToCIImage(outputTexture: outputTexture.texture, size: size)
        return ciImage
    }
    
    private func createModelInput(_ pixelBuffer: CVPixelBuffer, size: CGSize) -> CVPixelBuffer {
        let unresizedRawInput = CIImage(cvPixelBuffer: pixelBuffer)
        let transform = CGAffineTransform(
            scaleX: Self.segmentationSize.width / size.width,
            y: Self.segmentationSize.height / size.height
        )
        let resizedRawInput = unresizedRawInput.transformed(by: transform)
        let inputPixelBuffer = createPixelBuffer(size: Self.segmentationSize)
        context.render(resizedRawInput, to: inputPixelBuffer)
        return inputPixelBuffer
    }
    
    private func createPixelBuffer(size: CGSize) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )
        guard
            let pixelBuffer = pixelBuffer
        else { fatalError("Could not create new input pixel buffer") }
        return pixelBuffer
    }
    
    private func createMaskBuffer(modelOutput: DeepLabV3Output) -> (MTLBuffer) {
        let segmentationMap = modelOutput.semanticPredictions
        let bufferLength = Int(Self.segmentationSize.width)
            * Int(Self.segmentationSize.height)
            * MemoryLayout<Int32>.stride
        guard
            let segmentationMaskBuffer = sharedMetalHeartDevice.device.makeBuffer(length: bufferLength)
        else { fatalError("Failed to create mask buffer") }

        memcpy(
            segmentationMaskBuffer.contents(),
            segmentationMap.dataPointer,
            segmentationMaskBuffer.length
        )
        return segmentationMaskBuffer
    }
    
    private func renderTextureToCIImage(outputTexture: MTLTexture, size: CGSize) -> CIImage {
        let kciOptions: [CIImageOption: Any] = [
            .colorSpace: CGColorSpaceCreateDeviceRGB()
        ]
        guard
            let ciImage = CIImage(mtlTexture: outputTexture, options: kciOptions)?
                .oriented(.downMirrored)
        else { fatalError("Failed to render output texture") }
        return ciImage
    }
    
    private func renderTexture(outputTexture: MTLTexture, size: CGSize) -> CVPixelBuffer {
        let kciOptions: [CIImageOption: Any] = [
            .colorSpace: CGColorSpaceCreateDeviceRGB()
        ]
        guard
            let maskImage = CIImage(mtlTexture: outputTexture, options: kciOptions)?
                .oriented(.downMirrored)
        else { fatalError("Failed to render output texture") }
        let outputPixelBuffer = createPixelBuffer(size: size)
        context.render(maskImage, to: outputPixelBuffer)
        return outputPixelBuffer
    }
}

