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
#include <Graphics/BSpline.hpp>
#include <Graphics/CIELAB.hpp>
#include <metal_stdlib>

using namespace geometry;
using namespace metal;

//===------------------------------------------------------------------------===
// • Gradient rendering
//===------------------------------------------------------------------------===

struct GradientVertex
{
    float4 position [[ position ]];
    float  u;
};

using GradientMesh = mesh<GradientVertex, nurbs::Interval, 6, 2, topology::triangle>;

struct GradientFragment
{
    GradientVertex  v;
    nurbs::Interval interval;
};

struct GradientPayload
{
    GradientVertex  vertices[6];
    nurbs::Interval interval;
};

[[fragment]] half4 gradient_fragment(GradientFragment input [[ stage_in ]] )
{
    const auto lab  = nurbs::calculate_value(input.interval, input.v.u);
    const auto lrgb = cielab::convert_to_linear_display_P3(lab);

    if ( all(lrgb == clamp(lrgb, float3(0.0f), float3(1.0f))) )
    {
        return half4( half3(lrgb), 1.0h );
    }
    else
    {
        return { 0.5h, 0.5h, 0.5h, 1.0h };
    }
}

[[mesh]] void gradient_mesh(GradientMesh                       output,
                            const object_data GradientPayload& payload [[ payload ]],
                            ushort                             tid     [[ thread_index_in_threadgroup ]])
{
    output.set_primitive_count(2);

    if (tid < 6)
    {
        output.set_vertex(tid, payload.vertices[tid]);
        output.set_index(tid, tid);
    }

    if (tid < 2)
    {
        output.set_primitive(tid, payload.interval);
    }
}

[[object]] void horizontal_gradient_object(object_data GradientPayload& payload     [[ payload ]],
                                           mesh_grid_properties         mesh_grid,
                                           constant CompositionData*    composition [[ buffer(0) ]],
                                           ushort3                      tid         [[ thread_position_in_grid ]])
{
    if ( 0 < tid.x ) {
        //  - only use the first thread
        return;
    }

    const auto gradient_index = tid.y;

    if ( composition->gradients.count <= gradient_index ) {
        return;
    }

    constant auto* gradient = data::cdata(composition, composition->gradients) + gradient_index;

    const auto i = tid.z;

    if ( bspline::max_intervals(gradient->knots.count) <= i ) {
        return;
    }

    constant auto* k = data::cdata(composition, gradient->knots);

    if ( k[i+3] >= k[i+4] ) {
        return;
    }

    const    auto  F      = bspline::calculate_interval_coefficients(k, i);
    constant auto* P      = data::cdata(composition, gradient->points);
    const    auto  region = composition->base_region + composition->offset*gradient_index;
    const    auto  frame  = geometry::make_device_rect(region, composition->grid_size);
    const    auto  x0     = mix(frame.left, frame.right, k[i+3]);
    const    auto  x1     = mix(frame.left, frame.right, k[i+4]);
    const    auto  du     = k[i+4] - k[i+3];

    payload.interval = {
        .f0 = F.f0,   .f1 = F.f1,   .f2 = F.f2,   .f3 = F.f3,
        .P0 = P[i+0], .P1 = P[i+1], .P2 = P[i+2], .P3 = P[i+3]
    };

    payload.vertices[0] = { .position = { x0, frame.bottom, 0.0f, 1.0f }, .u = 0.0f };
    payload.vertices[1] = { .position = { x0, frame.top,    0.0f, 1.0f }, .u = 0.0f };
    payload.vertices[2] = { .position = { x1, frame.bottom, 0.0f, 1.0f }, .u = du   };

    payload.vertices[3] = { .position = { x1, frame.bottom, 0.0f, 1.0f }, .u = du   };
    payload.vertices[4] = { .position = { x0, frame.top,    0.0f, 1.0f }, .u = 0.0f };
    payload.vertices[5] = { .position = { x1, frame.top,    0.0f, 1.0f }, .u = du   };

    mesh_grid.set_threadgroups_per_grid({ 1, 1, 1});
}

[[object]] void vertical_gradient_object(object_data GradientPayload& payload     [[ payload ]],
                                         mesh_grid_properties         mesh_grid,
                                         constant CompositionData*    composition [[ buffer(0) ]],
                                         ushort3                      tid         [[ thread_position_in_grid ]])
{
    if ( 0 < tid.x ) {
        //  - only use the first thread
        return;
    }

    const auto gradient_index = tid.y;

    if ( composition->gradients.count <= gradient_index ) {
        return;
    }

    constant auto* gradient = data::cdata(composition, composition->gradients) + gradient_index;

    const auto i = tid.z;

    if ( bspline::max_intervals(gradient->knots.count) <= i ) {
        return;
    }

    constant auto* k = data::cdata(composition, gradient->knots);

    if ( k[i+3] >= k[i+4] ) {
        return;
    }

    const    auto  F      = bspline::calculate_interval_coefficients(k, i);
    constant auto* P      = data::cdata(composition, gradient->points);
    const    auto  region = composition->base_region + composition->offset*gradient_index;
    const    auto  frame  = geometry::make_device_rect(region, composition->grid_size);
    const    auto  y0     = mix(frame.bottom, frame.top, k[i+3]);
    const    auto  y1     = mix(frame.bottom, frame.top, k[i+4]);
    const    auto  du     = k[i+4] - k[i+3];

    payload.interval = {
        .f0 = F.f0,   .f1 = F.f1,   .f2 = F.f2,   .f3 = F.f3,
        .P0 = P[i+0], .P1 = P[i+1], .P2 = P[i+2], .P3 = P[i+3]
    };

    payload.vertices[0] = { .position = { frame.left,  y0, 0.0f, 1.0f }, .u = 0.0f };
    payload.vertices[1] = { .position = { frame.left,  y1, 0.0f, 1.0f }, .u = du   };
    payload.vertices[2] = { .position = { frame.right, y0, 0.0f, 1.0f }, .u = 0.0f };

    payload.vertices[3] = { .position = { frame.right, y0, 0.0f, 1.0f }, .u = 0.0f };
    payload.vertices[4] = { .position = { frame.left,  y1, 0.0f, 1.0f }, .u = du   };
    payload.vertices[5] = { .position = { frame.right, y1, 0.0f, 1.0f }, .u = du   };

    mesh_grid.set_threadgroups_per_grid({ 1, 1, 1});
}
