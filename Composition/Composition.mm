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

        try
        {
            auto [composition, rsrcIt] = data::prepare_resource_after(_compositionBuffer.contents,
                                                                      compositionBufferLength,
                                                                      CompositionData {
                .grid_size = { 40, 40 },
                .regions   = { 0 }
            });

            auto regions = data::make_vector(composition->regions, rsrcIt);

            const auto outer_rgn   = geometry::make_region_of_size(composition->grid_size);
            const auto content_rgn = geometry::inset(outer_rgn, 1);

            const auto d0  = geometry::subdivide_from_left  (content_rgn,      10u, 1u);
            const auto dl0 = geometry::subdivide_from_bottom(std::get<0>(d0),  11u, 1u);
            const auto dl1 = geometry::subdivide_from_bottom(std::get<2>(dl0), 13u, 1u);
            const auto dr0 = geometry::subdivide_from_bottom(std::get<2>(d0),  11u, 1u);
            const auto dr1 = geometry::subdivide_from_right (std::get<0>(dr0),  4u, 1u);
            const auto dr2 = geometry::subdivide_from_bottom(std::get<0>(dr1),  5u, 1u);

            regions.push_back( std::get<0>(dl0) );
            regions.push_back( std::get<0>(dl1) );
            regions.push_back( std::get<2>(dl1) );
            regions.push_back( std::get<2>(dr0) );
            regions.push_back( std::get<2>(dr1) );
            regions.push_back( std::get<0>(dr2) );
            regions.push_back( std::get<2>(dr2) );

            // • Properties
            //
            _resourceOffset = data::distance( composition, rsrcIt.get() );

            self->composition = composition;
        }
        catch ( ... )
        {
            return nil;
        }

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

- (nonnull id<MTLBuffer>)resourceBuffer {

    return _compositionBuffer;
}

- (NSInteger)instanceCount {

    return composition->regions.count;
}

@end
