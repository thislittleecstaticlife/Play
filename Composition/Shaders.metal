//
//  Shaders.metal
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

#include <Composition/Pattern.hpp>
#include <metal_stdlib>

using namespace geometry;
using namespace metal;

//===------------------------------------------------------------------------===
// • white_fragment
//===------------------------------------------------------------------------===

[[fragment]] half4 white_fragment(void)
{
    return { 1.0h, 1.0h, 1.0h, 1.0h };
}

//===------------------------------------------------------------------------===
// • pattern_vertex
//===------------------------------------------------------------------------===

[[vertex]] float4 pattern_vertex(constant Pattern& pattern [[ buffer(0)   ]],
                                 ushort            vid     [[ vertex_id   ]],
                                 ushort            iid     [[ instance_id ]])
{
    // • Clockwise quad triangle strip
    //
    //  1   3
    //  | \ |
    //  0   2
    //
    const auto offset  = pattern.offset * iid;
    const auto region  = pattern.base_region + offset;
    const auto rect    = geometry::make_device_rect(region, pattern.grid_size);

    const auto is_left = 0 != (vid & 0b10);
    const auto nx      = is_left ? rect.left : rect.right;

    const auto is_top  = 0 != (vid & 0b01);
    const auto ny      = is_top ? rect.top : rect.bottom;

    return { nx, ny, 0.0f, 1.0f };
}
