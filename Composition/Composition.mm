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

#import <Graphics/BSpline.hpp>
#import <Graphics/CIELAB.hpp>

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

        // • Gradient buffer
        //
        const auto gradientBufferSize = uint32_t{ 1024 };

        _gradientBuffer = [device newBufferWithLength:gradientBufferSize options:0];

        if (nil == _gradientBuffer) {
            return nil;
        }

        auto formatter = data::Formatter(_gradientBuffer.contents, gradientBufferSize);

        auto composition = formatter.assign_root( CompositionData {
            .content_region = geometry::make_region({ 4, 4 }, {  8, 32 }),
            .border_region  = geometry::make_region({ 3, 3 }, { 10, 34 }),
            .grid_size      = { 40, 40 },
            .offset         = { 12, 0 },
            .gradients      = { 0 },
            .border_color   = cielab::convert_to_linear_display_P3({ 45.0f, 1.0f, 2.0f })
        } );

        // • Insert three empty gradients and initialize the first
        //
        auto gradients = data::append( formatter, composition->gradients, {
            { 0 },
            { 0 },
            { 0 }
        } );

        //  - Knots
        //
        data::append( formatter, gradients[0].knots, {
            0.0f, 0.0f, 0.0f, 0.0f,
            0.45f,
            0.50f,
            0.55f,
            1.0f, 1.0f, 1.0f, 1.0f
        } );

        //  - Points
        //
        const auto begin_color = simd::float4{ 8.5f,  5.5f, -8.5f, 1.0f };
        const auto end_color   = simd::float4{ 5.5f, -2.5f, -5.5f, 1.0f };

        const auto points0 = data::append( formatter, gradients[0].points, {
            begin_color, begin_color,
            simd::float4{ 20.0f,  40.0f,  60.0f, 1.0f },
            simd::float4{ 75.0f, -15.0f,  30.0f, 0.3f },
            simd::float4{ 15.0f, -12.0f, -32.0f, 1.0f },
            end_color, end_color
        } );

        //  - Reference the first gradient's knots directly in the second, but change a weight
        //
        gradients[1].knots = gradients[0].knots;

        auto points1 = data::append( formatter, gradients[1].points,
                                     points0.begin(), points0.end() );
        points1[3].w = 1.0f;

        //  - Reference the second gradient's points in the third, but use different knots
        //
        gradients[2].points = gradients[1].points;

        data::append( formatter, gradients[2].knots, {
            0.0f, 0.0f, 0.0f, 0.0f,
            0.25f,
            0.30f,
            0.35f,
            1.0f, 1.0f, 1.0f, 1.0f
        } );

        // • Background color
        //
        _backgroundColor = cielab::convert_to_linear_display_P3({ 15.0f, -1.0f, -2.0f });

        // • Aspect ratio
        //
        const auto aspect_gcd = std::gcd(composition->grid_size.x, composition->grid_size.y);

        _aspectRatio = {
            composition->grid_size.x / aspect_gcd,
            composition->grid_size.y / aspect_gcd
        };

        // • Maximum interval count across all gradients
        //
        const auto maxKnotsIt = std::max_element(gradients.begin(), gradients.end(),
                                                 [](const auto& lhs, const auto& rhs) -> bool {

            return lhs.knots.count < rhs.knots.count;
        });

        _maxIntervalCount = bspline::max_intervals(maxKnotsIt->knots.count);

        // • Keep a pointer
        //
        self->composition = composition;
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties
//===------------------------------------------------------------------------===

- (NSInteger)gradientCount {

    return composition->gradients.count;
}

@end
