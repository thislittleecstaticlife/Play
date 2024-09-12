//
//  CGContext+Play.swift
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

import QuartzCore
import Metal

//===------------------------------------------------------------------------===
// MARK: - extension CGContext
//===------------------------------------------------------------------------===

extension CGContext {

    static func make( width: Int, height: Int, pixel: BitmapPixelDescription,
                      colorSpaceName: CFString ) -> CGContext? {

        return BitmapDescription(width: width, height: height, pixel: pixel,
                                 colorSpaceName: colorSpaceName)?
            .makeContext()
    }

    static func make( from texture: MTLTexture,
                      colorSpace: CGColorSpace,
                      alphaType: AlphaType = .none ) -> CGContext? {

        guard let pixel = BitmapPixelDescription(pixelFormat: texture.pixelFormat,
                                                 alphaType: alphaType) else {
            return nil
        }

        return BitmapDescription(width: texture.width, height: texture.height, pixel: pixel,
                                 colorSpace: colorSpace)?
            .makeContext()
    }
}
