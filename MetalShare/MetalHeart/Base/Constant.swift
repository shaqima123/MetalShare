//
//  Constant.swift
//  MetalShare
//
//  Created by shaoqianming on 2021/6/22.
//

import Foundation
import Metal

public let imageVertices : [Float] = [-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0]
public let textureCoordinates : [Float] = [0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0]

enum FunctionName {
    static let OneInputVertex = "oneInputVertex"
    static let TwoInputVertex = "twoInputVertex"
    static let PassthroughFragment = "passthroughFragment"
    
    static func defaultVertexFunctionNameForInputs(inputCount:UInt) -> String {
        switch inputCount {
        case 1:
            return OneInputVertex
        case 2:
            return TwoInputVertex
        default:
            return OneInputVertex
        }
    }
}

public enum RenderColor {
    static let clearColor = MTLClearColorMake(190.0/255, 231.0/255, 233.0/255, 1)
}
