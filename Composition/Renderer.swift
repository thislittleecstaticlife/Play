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
    let depthFormat = MTLPixelFormat.depth32Float
    let colorspace  : CGColorSpace
    let device      : MTLDevice
    let composition : Composition

    //===--------------------------------------------------------------------===
    // MARK: • Properties (Private)
    //
    private let renderPipelineState : MTLRenderPipelineState
    private let depthState          : MTLDepthStencilState
    private var textures            : (multisample: MTLTexture, depth: MTLTexture)?

    //===--------------------------------------------------------------------===
    // MARK: • Initilization
    //
    init?(library: MTLLibrary, composition: Composition) {

        self.device = library.device

        // • Color space
        //
        guard let colorspace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        // • Render pipeline
        //
        guard let triangleVertex = library.makeFunction(name: "triangle_vertex"),
              let passThroughFragment = library.makeFunction(name: "pass_through_fragment") else {

            return nil
        }

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = self.pixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat      = self.depthFormat
        renderPipelineDescriptor.vertexFunction                  = triangleVertex
        renderPipelineDescriptor.fragmentFunction                = passThroughFragment
        renderPipelineDescriptor.rasterSampleCount               = 4

        guard let renderPipelineState =
                try? device.makeRenderPipelineState(descriptor: renderPipelineDescriptor) else {

            return nil
        }

        // • Depth/stencil state
        //
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled  = true

        guard let depthState =
                device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {

            return nil
        }

        // • Assign properties
        //
        self.colorspace          = colorspace
        self.composition         = composition
        self.renderPipelineState = renderPipelineState
        self.depthState          = depthState
    }

    //===--------------------------------------------------------------------===
    // MARK: • Methods
    //
    @discardableResult
    func draw(to outputTexture: MTLTexture, with commandBuffer: MTLCommandBuffer) -> Bool {

        // • Memoryless multi-sample and depth textures
        //
        guard let (multisampleTexture, depthTexture) = intermediateTextures(for: outputTexture) else {
            return false
        }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture        = multisampleTexture
        renderPassDescriptor.colorAttachments[0].resolveTexture = outputTexture
        renderPassDescriptor.colorAttachments[0].clearColor     = .init(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].loadAction     = .clear
        renderPassDescriptor.colorAttachments[0].storeAction    = .multisampleResolve

        renderPassDescriptor.depthAttachment.texture     = depthTexture
        renderPassDescriptor.depthAttachment.clearDepth  = 1.0
        renderPassDescriptor.depthAttachment.loadAction  = .clear
        renderPassDescriptor.depthAttachment.storeAction = .dontCare

        guard let renderEncoder =
                commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {

            return false
        }

        renderEncoder.setDepthStencilState(depthState)
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(composition.compositionBuffer, offset: 0, index: 0)

        renderEncoder.drawPrimitives( type: .triangleStrip, vertexStart: 0, vertexCount: 4,
                                      instanceCount: composition.instanceCount )
        renderEncoder.endEncoding()

        return true
    }

    //===--------------------------------------------------------------------===
    // MARK: • Private Methods
    //
    private func intermediateTextures(for outputTexture: MTLTexture) -> (MTLTexture, MTLTexture)? {

        if let textures,
           textures.multisample.width == outputTexture.width,
           textures.multisample.height == outputTexture.height {

            return textures
        }

        // • Multi-sample texture descriptor
        //
        let multisampleTextureDescriptor = MTLTextureDescriptor()
        multisampleTextureDescriptor.textureType = .type2DMultisample
        multisampleTextureDescriptor.pixelFormat = self.pixelFormat
        multisampleTextureDescriptor.usage       = .renderTarget
        multisampleTextureDescriptor.storageMode = .memoryless
        multisampleTextureDescriptor.width       = outputTexture.width
        multisampleTextureDescriptor.height      = outputTexture.height
        multisampleTextureDescriptor.sampleCount = 4

        // • Depth texture descriptor (only pixel format differs from multisample texture)
        //
        let depthTextureDecriptor = multisampleTextureDescriptor.copy() as! MTLTextureDescriptor
        depthTextureDecriptor.pixelFormat = self.depthFormat

        guard let multisampleTexture = device.makeTexture(descriptor: multisampleTextureDescriptor),
              let depthTexture = device.makeTexture(descriptor: depthTextureDecriptor) else {

            return nil
        }

        textures = (multisampleTexture, depthTexture)

        return textures
    }
}
