/* Copyright (c) 2018 PaddlePaddle Authors. All Rights Reserved.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. */

import Metal
import Foundation

protocol Runable {
    func run(device: MTLDevice, buffer: MTLCommandBuffer) throws
    func runImpl(device: MTLDevice,buffer: MTLCommandBuffer) throws
    func delogOutput()
}

extension Runable where Self: OperatorProtocol{
    func run(device: MTLDevice, buffer: MTLCommandBuffer) throws {
        do {
            try runImpl(device: device, buffer: buffer)
        } catch let error {
            throw error
        }
//        print(type + ": " + para.outputDesc())
    }
    
    func delogOutput() {
        print(type + ": has no implementation" )
    }
}

protocol Creator where Self: OperatorProtocol{
    associatedtype OpType: OperatorProtocol & Runable & InferShaperable
    static func creat(device: MTLDevice, opDesc: OpDesc, inScope: Scope) throws -> OpType
}

extension Creator where Self: OperatorProtocol {
    static func creat(device: MTLDevice, opDesc: OpDesc, inScope: Scope) throws -> OpType {
        do {
            return try OpType.provide(device:device, opDesc: opDesc, inScope: inScope)
        } catch let error {
            throw error
        }
    }
}

protocol InferShaperable {
    func inferShape()
}

protocol OperatorProtocol {
    associatedtype ParamType: OpParam
    associatedtype KerType:  Computable
    var type: String { get }
    var inputs: [String : [String]] { get }
    var paraInputs: [String : [String]] { get }
    var outpus: [String : [String]] { get }
    var attrs: [String : Attr] { get }
    var para: ParamType { get }
    var kernel: KerType { get }
    init(device: MTLDevice, opDesc: OpDesc, inScope: Scope) throws
}

extension OperatorProtocol {
    static func provide(device: MTLDevice, opDesc: OpDesc, inScope: Scope) throws -> Self {
        do {
            return try Self.init(device: device, opDesc: opDesc, inScope: inScope)
        } catch let error {
            throw error
        }
    }
}


class Operator <ParameterType: OpParam, KernelType:  Computable>: OperatorProtocol{
    typealias ParamType = ParameterType
    typealias KerType = KernelType
    let type: String
    let inputs: [String : [String]]
    let paraInputs: [String : [String]]
    let outpus: [String : [String]]
    let attrs: [String : Attr]
    let para: ParamType
    var kernel: KerType
    required init(device: MTLDevice, opDesc: OpDesc, inScope: Scope) throws {
        type = opDesc.type
        inputs = opDesc.inputs
        outpus = opDesc.outputs
        attrs =  opDesc.attrs
        paraInputs = opDesc.paraInputs
        kernel = KerType.init(device: device)
        do {
            para = try ParamType.init(opDesc:opDesc, inScope: inScope)
        } catch let error {
            throw error
        }
    }
}

// op infos
let gFetchType          = "fetch"
let gFeedType           = "feed"
let gConvType           = "conv2d"
let gBatchNormType      = "batch_norm"
let gReluType           = "relu"
let gElementwiseAdd     = "elementwise_add"

let opInfos = [gConvType         : (inputs: ["Input"], outputs: ["Output"]),
               gBatchNormType    : (inputs: ["X"], outputs: ["Y"]),
               gReluType         : (inputs: ["X"], outputs: ["Out"]),
               gElementwiseAdd   : (inputs: ["X", "Y"], outputs: ["Out"]),
               gFeedType         : (inputs: ["X"], outputs: ["Out"]),
               gFetchType        : (inputs: ["X"], outputs: ["Out"])]
