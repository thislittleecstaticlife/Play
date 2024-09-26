//
//  AllocationTests.mm
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

#import <XCTest/XCTest.h>
#import <Data/Allocation.hpp>

#import <vector>

using namespace data;

//===------------------------------------------------------------------------===
#pragma mark - AllocationTests
//===------------------------------------------------------------------------===

@interface AllocationTests : XCTestCase

@end

//===------------------------------------------------------------------------===
#pragma mark - AllocationTests Implementation
//===------------------------------------------------------------------------===

@implementation AllocationTests

- (void)testNewReservation {

    try
    {
        auto contents_length = uint32_t{ 1024 };
        auto contents        = std::make_unique<uint8_t[]>(contents_length);
        auto dataIt          = prepare_layout(contents.get(), 0, contents_length);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        auto allocIt = detail::reserve(dataIt, 34);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        XCTAssertEqual( allocIt->identifier, AtomID::allocation );
        XCTAssertEqual( allocIt.offset(), atom_header_length );
        XCTAssertEqual( allocIt.contents_size(), 48 ); // aligned_size(34) = 48
        XCTAssertEqual( std::next(dataIt), allocIt );

        auto alloc2It = detail::reserve(dataIt, 512);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        XCTAssertEqual( alloc2It->identifier, AtomID::allocation );
        XCTAssertEqual( alloc2It->length, 528 );
        XCTAssertEqual( alloc2It.offset(), 80 );
        XCTAssertEqual( alloc2It.contents_size(), 512 );

        // • Test iterators
        //
        {
            auto testAlloc1It = std::next(dataIt);

            XCTAssertEqual( testAlloc1It->identifier, AtomID::allocation );
            XCTAssertEqual( testAlloc1It, allocIt );

            auto testAlloc2It = std::next(testAlloc1It);

            XCTAssertEqual( testAlloc2It->identifier, AtomID::allocation );
            XCTAssertEqual( testAlloc2It, alloc2It );

            auto freeIt = std::next(testAlloc2It);

            XCTAssertEqual( freeIt->identifier, AtomID::free );
            XCTAssertTrue( std::next(freeIt).is_end() );
        }

        // • Deallocation
        //
        detail::free(allocIt);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        // • Test iterators
        {
            auto free1It = std::next(dataIt);

            XCTAssertEqual( free1It->identifier, AtomID::free );
            XCTAssertEqual( free1It->length, 64 );
            XCTAssertEqual( free1It->previous, dataIt->length );

            auto alloc2It = std::next(free1It);

            XCTAssertEqual( alloc2It->identifier, AtomID::allocation );
            XCTAssertEqual( alloc2It->length, 528 );
            XCTAssertEqual( alloc2It->previous,   64 );

            auto free2It = std::next(alloc2It);

            XCTAssertEqual( free2It->identifier, AtomID::free );
            XCTAssertEqual( free2It->previous, 528 );
            XCTAssertTrue( std::next(free2It).is_end() );
        }

        // • Deallocate second
        //
        detail::free(alloc2It);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        // • Test iterators
        {
            auto coalescedFreeIt = std::next(dataIt);

            XCTAssertEqual( coalescedFreeIt->identifier, AtomID::free );
            XCTAssertEqual( coalescedFreeIt->length, contents_length - 2*atom_header_length );
            XCTAssertEqual( coalescedFreeIt->previous, dataIt->length );
            XCTAssertTrue( std::next(coalescedFreeIt).is_end() );
        }
    }
    catch ( ... )
    {
        XCTFail();
    }
}

- (void)testReallocation {

    try
    {
        auto contents_length = uint32_t{ 1024 };
        auto contents        = std::make_unique<uint8_t[]>(contents_length);
        auto dataIt          = prepare_layout(contents.get(), 0, contents_length);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        // • First reservation
        //
        auto allocIt = detail::reserve(dataIt, 34);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        XCTAssertEqual( allocIt->length,  64 );
        XCTAssertEqual( allocIt.offset(), 16 );
        XCTAssertEqual( allocIt.contents_size(), 48 );

        // • Second reservation
        //
        auto alloc2It = detail::reserve(dataIt, 512);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        XCTAssertEqual( alloc2It->length, 528 );
        XCTAssertEqual(alloc2It.offset(), 80 );
        XCTAssertEqual( alloc2It.contents_size(), 512 );

        // • Just for coverage, perform a same-size reallocation (no-op)
        //
        auto sameSizeIt = detail::reserve(dataIt, allocIt, 42);

        XCTAssertEqual( sameSizeIt, allocIt );
        XCTAssertEqual( sameSizeIt.offset(), 16 );
        XCTAssertEqual( sameSizeIt.contents_size(), 48 );

        // • First shrink the second
        //
        auto shrinkIt = detail::reserve(dataIt, alloc2It, 480);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        XCTAssertEqual( shrinkIt, alloc2It );
        XCTAssertEqual( shrinkIt.offset(), 80 );
        XCTAssertEqual( shrinkIt->length, atom_header_length + 480 );

        // • Reallocation of the second will extend it into the immediately following free space
        //
        auto realloc2It = detail::reserve(dataIt, alloc2It, 540);

        XCTAssertEqual( realloc2It, alloc2It );
        XCTAssertEqual( realloc2It.offset(), 80 );
        XCTAssertEqual( alloc2It.offset(), 80 );
        XCTAssertEqual( realloc2It->length, atom_header_length + 544 );
        XCTAssertEqual( alloc2It->length, realloc2It->length );

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        // • Reallocation of the first will move it past the second
        //
        auto reallocIt = detail::reserve(dataIt, allocIt, 120);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        XCTAssertNotEqual( reallocIt, allocIt );
        XCTAssertEqual( reallocIt.offset(), 640 );
        XCTAssertEqual( reallocIt.contents_size(), 128 );
    }
    catch ( ... )
    {
        XCTFail();
    }
}

@end
