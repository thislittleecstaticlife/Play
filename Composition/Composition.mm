//
//  Composition.mm
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

#import "Composition.h"
#import "CompositionData.hpp"

#import <numeric>

//===------------------------------------------------------------------------===
//
#pragma mark - Composition Implementation
//
//===------------------------------------------------------------------------===

@implementation Composition
{
    const CompositionData* composition;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device {

    self = [super init];

    if (nil != self) {

        // • Composition data buffer
        //
        const auto bufferLength = uint32_t{ 512 };

        _compositionBuffer = [device newBufferWithLength:bufferLength options:0];

        if (nil == _compositionBuffer) {
            return nil;
        }

        auto formatter = data::Formatter(_compositionBuffer.contents, bufferLength);

        auto composition = formatter.assign_root( CompositionData {
            .grid_size   = { 5, 5 },
            .depth_scale = 4,
            .triangles   = { 0 },
        } );

        // • Insert three triangles
        //
        data::append( formatter, composition->triangles, {
            {
                .v = {
                    { 0, 0 },
                    { 5, 0 },
                    { 5, 5 }
                },
                .depth = 3,
                .color = { 1, 1, 1, 1 }
            },
            {
                .v = {
                    { 4, 4 },
                    { 1, 4 },
                    { 1, 1 }
                },
                .depth = 3,
                .color = { 1, 1, 1, 1 }
            },
            {
                .v = {
                    { 1, 1 },
                    { 4, 1 },
                    { 4, 4 }
                },
                .depth = 2,
                .color = { 0, 0, 0, 1 }
            }
        } );

        // • Aspect ratio
        //
        const auto aspect_gcd = std::gcd(composition->grid_size.x, composition->grid_size.y);

        _aspectRatio = {
            composition->grid_size.x / aspect_gcd,
            composition->grid_size.y / aspect_gcd
        };

        // • Keep a pointer
        //
        self->composition = composition;
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties
//===------------------------------------------------------------------------===

- (NSInteger)instanceCount {

    return composition->triangles.count;
}

@end
