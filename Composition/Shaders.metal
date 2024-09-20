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

#include <Composition/CompositionData.hpp>
#include <metal_stdlib>

using namespace geometry;
using namespace metal;

//===------------------------------------------------------------------------===
// ColorVertex
//===------------------------------------------------------------------------===

struct ColorVertex
{
    float4 position [[ position ]];
    half4  color;
};

//===------------------------------------------------------------------------===
// • pass_through_fragment
//===------------------------------------------------------------------------===

[[fragment]] half4 pass_through_fragment(ColorVertex in [[ stage_in ]])
{
    return in.color;
}

//===------------------------------------------------------------------------===
// • triangle_vertex
//===------------------------------------------------------------------------===

[[vertex]] ColorVertex triangle_vertex(constant CompositionData* composition [[ buffer(0)   ]],
                                       ushort                    vid         [[ vertex_id   ]],
                                       ushort                    iid         [[ instance_id ]])
{
    const auto triangle      = data::cdata(composition, composition->triangles)[iid];
    const auto source_vertex = triangle.v[vid];

    const auto dest_vertex = simd::float4 {
        -1.0f + 2.0f*static_cast<float>(source_vertex.x) / static_cast<float>(composition->grid_size.x),
         1.0f - 2.0f*static_cast<float>(source_vertex.y) / static_cast<float>(composition->grid_size.y),
        static_cast<float>(triangle.depth) / static_cast<float>(composition->depth_scale),
        1.0f
    };

    return {
        .position = dest_vertex,
        .color    = half4(triangle.color)
    };
}
