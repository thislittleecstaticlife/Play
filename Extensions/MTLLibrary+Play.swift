//
//  MTLLibrary+Play.swift
//
//  Copyright © 2024 Robert Guequierre
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Metal

//===------------------------------------------------------------------------===
// MARK: - extension MTLLibrary
//===------------------------------------------------------------------------===

extension MTLLibrary {

    //===--------------------------------------------------------------------===
    // MARK: • Pipeline State Creation
    //
    func makeComputePipelineState(functionName: String) -> MTLComputePipelineState? {

        guard let computeFunction = self.makeFunction(name: functionName),
              let pipelineState = try? self.device.makeComputePipelineState(function: computeFunction) else {

            return nil
        }

        // • Having never seen a SIMD group width other than 32, catch myself in order to verify
        //
        precondition( 32 == pipelineState.threadExecutionWidth )

        return pipelineState
    }

    func makeComputePipelineState( functionName: String,
                                   tileWidth: Int,
                                   tileHeight: Int ) -> MTLComputePipelineState? {

        guard let computeFunction = self.makeFunction(name: functionName),
              let computePipeline =
                try? self.device.makeComputePipelineState(function: computeFunction) else {

            return nil
        }

        precondition( tileWidth*tileHeight <= computePipeline.maxTotalThreadsPerThreadgroup
                      && tileWidth == computePipeline.threadExecutionWidth )

        return computePipeline
    }

    func makeRenderPipelineState(vertexFunctionName: String, pixelFormat: MTLPixelFormat)
    -> MTLRenderPipelineState? {

        guard let vertexFunction = self.makeFunction(name: vertexFunctionName) else {
            return nil
        }

        let renderDescriptor = MTLRenderPipelineDescriptor()

        renderDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        renderDescriptor.vertexFunction                  = vertexFunction
        renderDescriptor.isRasterizationEnabled          = false

        return try? self.device.makeRenderPipelineState(descriptor: renderDescriptor)
    }

    func makeRenderPipelineState( vertexFunctionName: String,
                                  fragmentFunctionName: String,
                                  pixelFormat: MTLPixelFormat,
                                  depthFormat: MTLPixelFormat? = nil ) -> MTLRenderPipelineState? {


        guard let vertexFunction   = self.makeFunction(name: vertexFunctionName),
              let fragmentFunction = self.makeFunction(name: fragmentFunctionName) else {

            return nil
        }

        let renderDescriptor = MTLRenderPipelineDescriptor()

        renderDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        renderDescriptor.vertexFunction                  = vertexFunction
        renderDescriptor.fragmentFunction                = fragmentFunction

        if let depthFormat {
            renderDescriptor.depthAttachmentPixelFormat = depthFormat
        }

        return try? self.device.makeRenderPipelineState(descriptor: renderDescriptor)
    }

    func makeRenderPipelineState( objectFunctionName: String,
                                  meshFunctionName: String,
                                  fragmentFunctionName: String,
                                  pixelFormat: MTLPixelFormat,
                                  depthFormat: MTLPixelFormat? = nil ) -> MTLRenderPipelineState? {


        guard let objectFunction   = self.makeFunction(name: objectFunctionName),
              let meshFunction     = self.makeFunction(name: meshFunctionName),
              let fragmentFunction = self.makeFunction(name: fragmentFunctionName) else {

            return nil
        }

        let renderDescriptor = MTLMeshRenderPipelineDescriptor()

        renderDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        renderDescriptor.objectFunction                  = objectFunction
        renderDescriptor.meshFunction                    = meshFunction
        renderDescriptor.fragmentFunction                = fragmentFunction

        if let depthFormat {
            renderDescriptor.depthAttachmentPixelFormat = depthFormat
        }

        guard let (pipelineState, _) =
                try? self.device.makeRenderPipelineState(descriptor: renderDescriptor,
                                                         options: []) else {
            return nil
        }

        // • Having never seen a SIMD group width other than 32, catch myself in order to verify
        //
        precondition( 32 == pipelineState.objectThreadExecutionWidth &&
                      32 == pipelineState.meshThreadExecutionWidth )

        return pipelineState
    }

    func makeRenderPipelineState(tileFunctionName: String, pixelFormat: MTLPixelFormat)
    -> MTLRenderPipelineState? {

        guard let tileFunction = self.makeFunction(name: tileFunctionName) else {
            return nil
        }

        let tileDescriptor = MTLTileRenderPipelineDescriptor()

        tileDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        tileDescriptor.tileFunction                    = tileFunction
        tileDescriptor.threadgroupSizeMatchesTileSize  = true

        return try? self.device.makeRenderPipelineState( tileDescriptor: tileDescriptor,
                                                         options: [],
                                                         reflection: nil )
    }
}
