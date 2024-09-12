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
#import "Pattern.hpp"

#import <numeric>

//===------------------------------------------------------------------------===
//
#pragma mark - Composition Implementation
//
//===------------------------------------------------------------------------===

@implementation Composition
{
    const Pattern* pattern;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device {

    self = [super init];

    if (nil != self) {

        // • Pattern buffer
        //
        _patternBuffer = [device newBufferWithLength:data::aligned_size<Pattern>()
                                             options:0];
        if (nil == _patternBuffer) {
            return nil;
        }

        auto pattern = static_cast<Pattern*>(_patternBuffer.contents);

        *pattern = {
            .grid_size   = { 10, 10 },
            .base_region = geometry::make_region({ 1, 1 }, { 8, 2 }),
            .offset      = { 0, 3 },
            .count       = 3
        };

        // • Aspect ratio
        //
        const auto aspect_gcd = std::gcd(pattern->grid_size.x, pattern->grid_size.y);

        _aspectRatio = {
            pattern->grid_size.x / aspect_gcd,
            pattern->grid_size.y / aspect_gcd
        };

        // • Keep a pointer
        //
        self->pattern = pattern;
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties
//===------------------------------------------------------------------------===

- (NSInteger)instanceCount {

    return pattern->count;
}

@end
