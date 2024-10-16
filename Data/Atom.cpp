//
//  Atom.cpp
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

#include <Data/Atom.hpp>

//===------------------------------------------------------------------------===
// • namespace data
//===------------------------------------------------------------------------===

namespace data
{

//===------------------------------------------------------------------------===
//
// • Validation
//
//===------------------------------------------------------------------------===

bool valid_alignment(const Atom* atom) noexcept
{
    if (   !is_aligned(atom)
        || !is_aligned(atom->length)
        || !is_aligned(atom->previous)
        || atom->length < atom_header_length )
    {
        return false;
    }

    return true;
}

bool valid_resource(const Atom* resource) noexcept
{
    if ( !is_aligned(resource)
        || AtomID::resource != resource->identifier
        || atom_header_length != resource->length
        || 0 != resource->previous )
    {
        return false;
    }

    return true;
}

bool valid_end(const Atom* end) noexcept
{
    if ( !is_aligned(end)
        || AtomID::end != end->identifier
        || atom_header_length != end->length
        || !is_aligned(end->previous) )
    {
        return false;
    }

    return true;
}

bool validate_layout(const void* contents, uint32_t contents_length) noexcept
{
    // • Contents alignment and length
    //
    if ( !valid_alignment_and_length(contents, contents_length) )
    {
        return false;
    }

    // • The first atom is 'rsrc'
    //
    const Atom* resource = reinterpret_cast<const Atom*>(contents);

    if ( !valid_resource(resource) )
    {
        return false;
    }

    // • The last atom is 'end ', which has no content
    //
    const auto end = unchecked::end(contents, contents_length);

    if ( AtomID::end != end->identifier || !unchecked::empty(end) ) {
        return false;
    }

    // • Validate each atom forward to 'end '
    //
    const Atom* curr = unchecked::next(resource);
    const Atom* prev = resource;

    for ( auto end_distance = contents_length - resource->length - end->length ;
          0 < end_distance ;
          end_distance -= curr->length, prev = curr, curr = unchecked::next(curr) )
    {
        if ( !is_aligned(curr->length) || end_distance < curr->length ) {
            return false;
        }

        if ( AtomID::allocation == curr->identifier )
        {
            // • There shall be no zero-length vector atoms
            //
            if ( unchecked::empty(curr) ) {
                return false;
            }
        }
        else if ( AtomID::free == curr->identifier )
        {
            // • There shall be no sequential free atoms
            //
            if ( AtomID::free == prev->identifier ) {
                return false;
            }
        }
        else
        {
            // • Currently only two atom types before 'end '
            //
            return false;
        }

        if (prev->length != curr->previous) {
            return false;
        }
    }

    if ( curr != end ) {
        return false;
    }

    return true;
}

//===------------------------------------------------------------------------===
//
// • Contents
//
//===------------------------------------------------------------------------===

AtomIterator prepare_resource( void* buffer, uint32_t buffer_length,
                               uint32_t resource_offset ) noexcept(false)
{
    // • Validate alignment and minimum possible size
    //
    if (   !is_aligned(buffer)
        || !is_aligned(buffer_length)
        || !is_aligned(resource_offset)
        || buffer_length < resource_offset + 2*sizeof(Atom) )
    {
        throw false;
    }

    // • Zero-init the leading data
    //
    if ( 0 < resource_offset )
    {
        std::memset(buffer, 0, resource_offset);
    }

    // • Resource
    //
    const auto resource_length = buffer_length - resource_offset;
    auto       resource_base   = static_cast<uint8_t*>(buffer) + resource_offset;

    auto resource = reinterpret_cast<Atom*>(resource_base);

    *resource = {
        .length     = atom_header_length,
        .identifier = AtomID::resource,
        0
    };

    // • End
    //
    auto end_offset = resource_length - atom_header_length;
    auto end        = unchecked::offset_by(resource_base, end_offset);

    if ( resource->length < end_offset )
    {
        // • Free
        //
        auto free = unchecked::next(resource);

        *free = {
            .length     = resource_length - 2*atom_header_length,
            .identifier = AtomID::free,
            .previous   = resource->length,
            0
        };

        *end = {
            .length     = atom_header_length,
            .identifier = AtomID::end,
            .previous   = free->length,
            0
        };

        return { resource, 0 };
    }
    else
    {
        *end = {
            .length     = atom_header_length,
            .identifier = AtomID::end,
            .previous   = resource->length,
            0
        };

        return { resource, 0 };
    }
}

} // namespace data
