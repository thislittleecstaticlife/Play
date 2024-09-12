//
//  Formatter.hpp
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

#include <cassert>
#include <memory>

//===------------------------------------------------------------------------===
// • namespace data
//===------------------------------------------------------------------------===

namespace data
{

//===------------------------------------------------------------------------===
//
// • Formatter
//
//===------------------------------------------------------------------------===

class Formatter
{
public:

    //===--------------------------------------------------------------------===
    // • Construction
    //
    template <typename Buffer_>
    constexpr Formatter(Buffer_* buffer, uint32_t buffer_length)
        :
            m_buffer        { reinterpret_cast<uint8_t*>(buffer) },
            m_buffer_length { buffer_length },
            m_root_offset   { 0u },
            m_current_offset{ 0u }
    {
        assert( is_aligned(buffer) && is_aligned(buffer_length) );
    }

    //===--------------------------------------------------------------------===
    // • Destruction
    //
    ~Formatter(void) = default;

private:

    //===--------------------------------------------------------------------===
    // • Construction/assignment (deleted)
    //
    Formatter(void) = delete;
    Formatter(const Formatter& ) = delete;

    Formatter& operator = (const Formatter& ) = delete;

public:

    //===--------------------------------------------------------------------===
    // • Public Methods (Accessors)
    //
    constexpr uint32_t remain_length(void) const noexcept
    {
        return m_buffer_length - m_current_offset;
    }

    //===--------------------------------------------------------------------===
    // • Public Methods (Root)
    //
    inline uint32_t current_offset(void) const noexcept
    {
        return m_current_offset;
    }

    inline uint32_t root_offset(void) const noexcept
    {
        return m_root_offset;
    }

    inline void reset_root(void) noexcept
    {
        m_root_offset = 0;
    }

public:

    //===--------------------------------------------------------------------===
    // • Public Methods (Root)
    //
    template <TrivialLayout Type_>
    Type_* assign_root(Type_&& source)
    {
        assert( sizeof(Type_) <= m_buffer_length );

        auto ptr = reinterpret_cast<Type_*>(m_buffer);

        std::construct_at( ptr, std::forward<Type_>(source) );

        m_current_offset = aligned_size<Type_>();
        m_root_offset    = 0;

        return ptr;
    }

    //===--------------------------------------------------------------------===
    // • Public Methods (Reservation)
    //
    template <TrivialLayout Type_>
    std::pair<Type_*,uint32_t> reserve(uint32_t count) noexcept
    {
        const auto reserve_size = aligned_size<Type_>(count);

        assert( reserve_size <= remain_length() ); //  - increase buffer size

        auto       ptr    = data::offset_by<Type_>(m_buffer, m_current_offset);
        const auto offset = m_current_offset;

        m_current_offset += reserve_size;

        return { ptr, offset };
    }

    template <TrivialLayout Type_>
    std::pair<Type_*,uint32_t> reserve_as_root(uint32_t count) noexcept
    {
        auto [ptr, offset] = reserve<Type_>(count);

        m_root_offset = offset;

        return { ptr, offset };
    }

private:

    // • Data members (Private)
    //
    uint8_t*    m_buffer;
    uint32_t    m_buffer_length;

    uint32_t    m_root_offset;
    uint32_t    m_current_offset;
};

} // namespace data
