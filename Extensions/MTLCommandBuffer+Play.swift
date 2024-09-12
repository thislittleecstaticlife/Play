//
//  MTLCommandBuffer+Play.swift
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
// MARK: - extension MTLCommandBuffer
//===------------------------------------------------------------------------===

extension MTLCommandBuffer {

    //===--------------------------------------------------------------------===
    // MARK: • Render command encoders
    //
    func makeRenderCommandEncoder(to texture: MTLTexture, slice: Int = 0) -> MTLRenderCommandEncoder? {

        let renderDescriptor = MTLRenderPassDescriptor()

        renderDescriptor.colorAttachments[0].texture     = texture
        renderDescriptor.colorAttachments[0].loadAction  = .dontCare
        renderDescriptor.colorAttachments[0].storeAction = .store
        renderDescriptor.colorAttachments[0].slice       = slice

        return makeRenderCommandEncoder(descriptor: renderDescriptor)
    }

    func makeRenderCommandEncoder(to texture: MTLTexture, slice: Int, clearColor: MTLClearColor)
    -> MTLRenderCommandEncoder? {

        let renderDescriptor = MTLRenderPassDescriptor()

        renderDescriptor.colorAttachments[0].texture     = texture
        renderDescriptor.colorAttachments[0].clearColor  = clearColor
        renderDescriptor.colorAttachments[0].loadAction  = .clear
        renderDescriptor.colorAttachments[0].storeAction = .store
        renderDescriptor.colorAttachments[0].slice       = slice

        return makeRenderCommandEncoder(descriptor: renderDescriptor)
    }

    func makeRenderCommandEncoder(to texture: MTLTexture, clearColor: MTLClearColor)
    -> MTLRenderCommandEncoder? {

        makeRenderCommandEncoder(to: texture, slice: 0, clearColor: clearColor)
    }

    //===--------------------------------------------------------------------===
    // MARK: • Blit commands for Indirect Command Buffers
    //
    func resetCommandsInBuffer(_ indirectCommandBuffer: MTLIndirectCommandBuffer) -> Bool {

        guard let resetEncoder = self.makeBlitCommandEncoder() else {
            return false
        }

        resetEncoder.resetCommandsInBuffer( indirectCommandBuffer,
                                            range: 0..<indirectCommandBuffer.size )
        resetEncoder.endEncoding()

        return true
    }

    func optimizeCommandsInBuffer(_ indirectCommandBuffer: MTLIndirectCommandBuffer) -> Bool {

        guard let optimizeEncoder = self.makeBlitCommandEncoder() else {
            return false
        }

        optimizeEncoder.optimizeIndirectCommandBuffer( indirectCommandBuffer,
                                                       range: 0..<indirectCommandBuffer.size )
        optimizeEncoder.endEncoding()

        return true
    }
}
