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

#import <Data/Atom.hpp>

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

        // • Composition buffer
        //
        const auto compositionBufferLength = uint32_t{ 256 };

        _compositionBuffer = [device newBufferWithLength:compositionBufferLength options:0];

        if (nil == _compositionBuffer) {
            return nil;
        }

        auto dataIt = data::prepare_layout(_compositionBuffer.contents,
                                           compositionBufferLength,
                                           CompositionData {
            .grid_size   = { 10, 10 },
            .base_region = geometry::make_region({ 1, 1 }, { 8, 2 }),
            .offset      = { 0, 3 },
            .count       = 3
        });

        // • Keep a pointer
        //
        composition = dataIt.contents<CompositionData>();

        // • Aspect ratio
        //
        const auto aspect_gcd = std::gcd(composition->grid_size.x, composition->grid_size.y);

        _aspectRatio = {
            composition->grid_size.x / aspect_gcd,
            composition->grid_size.y / aspect_gcd
        };
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties
//===------------------------------------------------------------------------===

- (NSInteger)compositionDataOffset {

    return data::atom_header_length;
}

- (NSInteger)instanceCount {

    return composition->count;
}

@end
