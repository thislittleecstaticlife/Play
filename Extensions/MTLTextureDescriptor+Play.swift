//
//  MTLTextureDescriptor+Play.swift
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
// MARK: - extension MTLTextureDescriptor
//===------------------------------------------------------------------------===

extension MTLTextureDescriptor {

    convenience init( pixelFormat: MTLPixelFormat, width: Int, height: Int,
                      usage: MTLTextureUsage? = nil ) {
        self.init()

        self.textureType = .type2D
        self.pixelFormat = pixelFormat
        self.width       = width
        self.height      = height

        if let usage = usage {
            self.usage = usage
        }
    }

    convenience init( pixelFormat: MTLPixelFormat, width: Int, height: Int,
                      arrayLength: Int, usage: MTLTextureUsage? = nil ) {
        self.init()

        self.textureType = .type2DArray
        self.pixelFormat = pixelFormat
        self.width       = width
        self.height      = height
        self.arrayLength = arrayLength

        if let usage = usage {
            self.usage = usage
        }
    }
}
