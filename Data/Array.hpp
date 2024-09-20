//
//  Array.hpp
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

#pragma once

#include <Data/Layout.hpp>

#if !defined ( __METAL_VERSION__ )
#include <Data/Formatter.hpp>
#include <algorithm>
#include <span>
#endif

//===------------------------------------------------------------------------===
// • namespace data
//===------------------------------------------------------------------------===

namespace data
{

//===------------------------------------------------------------------------===
// • ArrayRef
//===------------------------------------------------------------------------===

template <TRIVIAL_LAYOUT Type_>
struct ArrayRef
{
    using value_type = Type_;

    uint32_t offset;
    uint32_t count;
};

#if !defined ( __METAL_VERSION__ )

static_assert( is_trivial_layout<ArrayRef<int>>(), "Unexpected layout" );
static_assert( is_referential<ArrayRef<int>>(), "Expected Referential" );

//===------------------------------------------------------------------------===
// • ArrayRef Utilities (Host)
//===------------------------------------------------------------------------===

template <TrivialLayout Type_>
constexpr bool empty(const ArrayRef<Type_>& ref) noexcept
{
    return 0 == ref.count;
}

template <TrivialLayout Type_>
constexpr uint32_t size(const ArrayRef<Type_>& ref) noexcept
{
    return ref.count;
}

template <TrivialLayout Root_, TrivialLayout Type_>
const Type_* cdata(const Root_* root, const ArrayRef<Type_>& ref) noexcept
{
    return offset_by<Type_>(root, ref.offset);
}

template <TrivialLayout Root_, TrivialLayout Type_>
const Type_* data(const Root_* root, const ArrayRef<Type_>& ref) noexcept
{
    return cdata(root, ref);
}

template <TrivialLayout Root_, TrivialLayout Type_>
Type_* data(Root_* root, const ArrayRef<Type_>& ref) noexcept
{
    return offset_by<Type_>(root, ref.offset);
}

//===------------------------------------------------------------------------===
// • Formatter Utilities
//===------------------------------------------------------------------------===

template <TrivialLayout Type_>
std::span<Type_> reserve( Formatter& formatter, ArrayRef<Type_>& ref,
                          uint32_t count ) noexcept
{
    auto [ptr, offset] = formatter.reserve<Type_>(count);

    ref.offset = offset;
    ref.count  = 0;

    return { ptr, count };
}

template <TrivialLayout Type_>
std::span<Type_> reserve_as_root( Formatter& formatter, ArrayRef<Type_>& ref,
                                  uint32_t count ) noexcept
{
    auto [ptr, offset] = formatter.reserve_as_root<Type_>(count);

    ref.offset = offset;
    ref.count  = 0;

    return { ptr, count };
}

template <TrivialLayout Type_>
std::span<Type_> append( Formatter& formatter, ArrayRef<Type_>& ref,
                         const std::initializer_list<Type_>& contents ) noexcept
{
    const auto count = static_cast<uint32_t>( contents.size() );
    const auto data  = reserve(formatter, ref, count);

    std::ranges::copy( contents, data.begin() );
    ref.count = count;

    return data;
}

template <TrivialLayout Type_>
std::span<Type_> append_as_root( Formatter& formatter, ArrayRef<Type_>& ref,
                                 const std::initializer_list<Type_>& contents ) noexcept
{
    const auto count = static_cast<uint32_t>( contents.size() );
    const auto data  = reserve_as_root(formatter, ref, count);

    std::ranges::copy( contents, data.begin() );
    ref.count = count;

    return data;
}

template <TrivialLayout Type_, std::forward_iterator SrcIter_>
    requires ( std::is_constructible_v<Type_, typename std::iterator_traits<SrcIter_>::value_type> )
std::span<Type_> append( Formatter& formatter, ArrayRef<Type_>& ref,
                         SrcIter_ src_begin, SrcIter_ src_end ) noexcept
{
    const auto count = static_cast<uint32_t>( std::distance(src_begin, src_end) );
    const auto data  = reserve(formatter, ref, count);

    std::copy( src_begin, src_end, data.begin() );
    ref.count = count;

    return data;
}

template <TrivialLayout Type_, std::forward_iterator SrcIter_>
    requires ( std::is_constructible_v<Type_, typename std::iterator_traits<SrcIter_>::value_type> )
std::span<Type_> append_as_root( Formatter& formatter, ArrayRef<Type_>& ref,
                                 SrcIter_ src_begin, SrcIter_ src_end ) noexcept
{
    const auto count = static_cast<uint32_t>( std::distance(src_begin, src_end) );
    const auto data  = reserve_as_root(formatter, ref, count);

    std::copy( src_begin, src_end, data.begin() );
    ref.count = count;

    return data;
}

#else // if defined ( __METAL_VERSION__ )

//===------------------------------------------------------------------------===
// • ArrayRef Utilities (Metal)
//===------------------------------------------------------------------------===

template <TRIVIAL_LAYOUT Root_, TRIVIAL_LAYOUT Type_>
constant Type_* cdata(constant Root_* root, ArrayRef<Type_> ref)
{
    return offset_by<Type_>(root, ref.offset);
}

template <TRIVIAL_LAYOUT Root_, TRIVIAL_LAYOUT Type_>
constant Type_* data(constant Root_* root, ArrayRef<Type_> ref)
{
    return cdata(root, ref);
}

#endif // defined ( __METAL_VERSION__ )

} // namespace data
