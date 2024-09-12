//
//  Renderer.swift
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

import Foundation
import Metal
import QuartzCore

//===------------------------------------------------------------------------===
//
// MARK: - Renderer
//
//===------------------------------------------------------------------------===

class Renderer {

    //===--------------------------------------------------------------------===
    // MARK: • Properties (Read-Only)
    //
    let pixelFormat = MTLPixelFormat.bgra8Unorm
    let colorspace  : CGColorSpace
    let device      : MTLDevice
    let composition : Composition

    //===--------------------------------------------------------------------===
    // MARK: • Properties (Private)
    //
    private let renderPipelineState : MTLRenderPipelineState

    //===--------------------------------------------------------------------===
    // MARK: • Initilization
    //
    init?(library: MTLLibrary, composition: Composition) {

        // • Color space
        //
        guard let colorspace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        // • Render pipeline
        //
        guard let renderPipelineState =
                library.makeRenderPipelineState(vertexFunctionName: "pattern_vertex",
                                                fragmentFunctionName: "white_fragment",
                                                pixelFormat: self.pixelFormat) else {
            return nil
        }

        // • Assign properties
        //
        self.colorspace          = colorspace
        self.device              = library.device
        self.composition         = composition
        self.renderPipelineState = renderPipelineState
    }

    //===--------------------------------------------------------------------===
    // MARK: • Methods
    //
    @discardableResult
    func draw(to outputTexture: MTLTexture, with commandBuffer: MTLCommandBuffer) -> Bool {

        let clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(to: outputTexture,
                                                                         clearColor: clearColor) else {
            return false
        }

        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(composition.patternBuffer, offset: 0, index: 0)

        renderEncoder.drawPrimitives( type: .triangleStrip, vertexStart: 0, vertexCount: 4,
                                      instanceCount: composition.instanceCount )
        renderEncoder.endEncoding()

        return true
    }
}
