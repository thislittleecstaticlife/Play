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
    let pixelFormat = MTLPixelFormat.rgba16Float
    let depthFormat = MTLPixelFormat.depth32Float
    let colorspace  : CGColorSpace
    let device      : MTLDevice
    let composition : Composition

    //===--------------------------------------------------------------------===
    // MARK: • Properties (Private)
    //
    private let gradientPipelineState : MTLRenderPipelineState
    private let borderPipelineState   : MTLRenderPipelineState
    private let depthState            : MTLDepthStencilState
    private var depthTexture          : MTLTexture?

    //===--------------------------------------------------------------------===
    // MARK: • Initilization
    //
    init?(library: MTLLibrary, composition: Composition) {

        // • Color space
        //
        guard let colorspace = CGColorSpace(name: CGColorSpace.linearDisplayP3) else {
            return nil
        }

        // • Gradient pipeline
        //
        guard let gradientPipelineState =
                library.makeRenderPipelineState( objectFunctionName: "vertical_gradient_object",
                                                 meshFunctionName: "gradient_mesh",
                                                 fragmentFunctionName: "gradient_fragment",
                                                 pixelFormat: self.pixelFormat,
                                                 depthFormat: self.depthFormat ) else {
            return nil
        }

        // • Border pipeline
        //
        guard let borderPipelineState =
                library.makeRenderPipelineState(vertexFunctionName: "border_vertex",
                                                fragmentFunctionName: "border_fragment",
                                                pixelFormat: self.pixelFormat,
                                                depthFormat: self.depthFormat ) else {
            return nil
        }

        // • Depth/stencil state
        //
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled  = true

        guard let depthState =
                library.device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {

            return nil
        }

        // • Assign properties
        //
        self.colorspace            = colorspace
        self.device                = library.device
        self.composition           = composition
        self.gradientPipelineState = gradientPipelineState
        self.borderPipelineState   = borderPipelineState
        self.depthState            = depthState
    }

    //===--------------------------------------------------------------------===
    // MARK: • Methods
    //
    @discardableResult
    func draw(to outputTexture: MTLTexture, with commandBuffer: MTLCommandBuffer) -> Bool {

        guard let depthTexture = depthTexture(for: outputTexture) else {
            return false
        }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture     = outputTexture
        renderPassDescriptor.colorAttachments[0].clearColor  = .init(color: composition.backgroundColor)
        renderPassDescriptor.colorAttachments[0].loadAction  = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        renderPassDescriptor.depthAttachment.texture     = depthTexture
        renderPassDescriptor.depthAttachment.clearDepth  = 1.0
        renderPassDescriptor.depthAttachment.loadAction  = .clear
        renderPassDescriptor.depthAttachment.storeAction = .dontCare

        guard let renderEncoder =
                commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {

            return false
        }

        // • Render the foreground gradient content
        //
        renderEncoder.setRenderPipelineState(gradientPipelineState)
        renderEncoder.setDepthStencilState(depthState)

        renderEncoder.setObjectBuffer(composition.gradientBuffer, offset: 0, index: 0)

        let threadsPerObjectThreadgroup = MTLSizeMake(gradientPipelineState.objectThreadExecutionWidth, 1, 1)
        let threadsPerMeshThreadgroup   = MTLSizeMake(gradientPipelineState.meshThreadExecutionWidth, 1, 1)

        renderEncoder.drawMeshThreads( MTLSizeMake(1, composition.gradientCount, composition.maxIntervalCount),
                                       threadsPerObjectThreadgroup: threadsPerObjectThreadgroup,
                                       threadsPerMeshThreadgroup: threadsPerMeshThreadgroup )

        // • Render the borders behind
        //
        renderEncoder.setRenderPipelineState(borderPipelineState)
        renderEncoder.setVertexBuffer(composition.gradientBuffer, offset: 0, index: 0)

        renderEncoder.drawPrimitives( type: .triangleStrip, vertexStart: 0, vertexCount: 4,
                                      instanceCount: composition.gradientCount )

        renderEncoder.endEncoding()

        return true
    }

    //===--------------------------------------------------------------------===
    // MARK: • Private Methods
    //
    private func depthTexture(for colorTexture: MTLTexture) -> MTLTexture? {

        if let depthTexture,
           depthTexture.width == colorTexture.width,
           depthTexture.height == colorTexture.height {

            return depthTexture
        }

        let depthTextureDescriptor = MTLTextureDescriptor()
        depthTextureDescriptor.textureType = .type2D
        depthTextureDescriptor.pixelFormat = self.depthFormat
        depthTextureDescriptor.width       = colorTexture.width
        depthTextureDescriptor.height      = colorTexture.height
        depthTextureDescriptor.depth       = 1
        depthTextureDescriptor.storageMode = .memoryless
        depthTextureDescriptor.usage       = .renderTarget

        depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)

        return depthTexture
    }
}
