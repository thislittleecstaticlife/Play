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
#import "Presentation.hpp"

#import <Graphics/BSpline.hpp>

#import <numeric>

//===------------------------------------------------------------------------===
//
#pragma mark - Composition Implementation
//
//===------------------------------------------------------------------------===

@implementation Composition
{
    const Gradient* gradient;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device {

    self = [super init];

    if (nil != self) {

        // • Gradient buffer
        //
        const auto gradientBufferSize = uint32_t{ 1024 };

        _gradientBuffer = [device newBufferWithLength:gradientBufferSize options:0];

        if (nil == _gradientBuffer) {
            return nil;
        }

        auto formatter = data::Formatter(_gradientBuffer.contents, gradientBufferSize);

        auto gradient = formatter.assign_root( Gradient {
            .output_region = geometry::make_region({ 1, 1 }, { 8, 8 }),
            .grid_size     = { 10, 10 }
        });

        // • Knots
        //
        data::append( formatter, gradient->knots, {
            0.0f, 0.0f, 0.0f, 0.0f,
            0.3400f,
            0.3401f,
            0.3402f,
            1.0f, 1.0f, 1.0f, 1.0f
        } );

        // • Points
        //
        const auto begin_color = simd::float4{ 8.5f,  5.5f, -8.5f, 1.0f };
        const auto end_color   = simd::float4{ 7.5f, -2.5f, -5.5f, 1.0f };

        data::append( formatter, gradient->points, {
            begin_color, begin_color,
            simd::float4{ 20.0f,  40.0f,  60.0f, 1.0f },
            simd::float4{ 75.0f, -15.0f,  30.0f, 0.3f },
            simd::float4{ 15.0f, -12.0f, -32.0f, 1.0f },
            end_color, end_color
        } );

        // • Aspect ratio
        //
        const auto aspect_gcd = std::gcd(gradient->grid_size.x, gradient->grid_size.y);

        _aspectRatio = {
            gradient->grid_size.x / aspect_gcd,
            gradient->grid_size.y / aspect_gcd
        };

        // • Keep a pointer
        //
        self->gradient = gradient;
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties
//===------------------------------------------------------------------------===

- (NSInteger)maxIntervalCount {

    return bspline::max_intervals(gradient->knots.count);
}

@end
