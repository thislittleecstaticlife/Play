//
//  VectorTests.mm
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
#import <Data/Vector.hpp>

#import <memory>

using namespace data;

//===------------------------------------------------------------------------===
#pragma mark - VectorTests
//===------------------------------------------------------------------------===

@interface VectorTests : XCTestCase

@end

//===------------------------------------------------------------------------===
#pragma mark - VectorTests Implementation
//===------------------------------------------------------------------------===

@implementation VectorTests

- (void)testReservation {

    try
    {
        auto contents_length = uint32_t{ 1024 };
        auto contents        = std::make_unique<uint8_t[]>(contents_length);
        auto dataIt          = prepare_layout(contents.get(), 0, contents_length);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        auto ref    = VectorRef<int>{ 0 };
        auto vector = Vector<int>{ dataIt, ref };

        XCTAssertEqual( vector.size(), 0 );
        XCTAssertTrue( vector.empty() );
        XCTAssertEqual( ref.offset, 0 );
        XCTAssertEqual( ref.count, 0 );

        try {
            vector.reserve(27);
        } catch ( ... ) {
            XCTFail();
        }

        auto expected_capacity = aligned_size<int>(27u) / sizeof(int);

        XCTAssertEqual( vector.capacity(), expected_capacity );
        XCTAssertEqual( vector.available(), vector.capacity() );
        XCTAssertEqual( vector.size(), 0 );

        XCTAssertEqual( ref.offset, 2*atom_header_length );

        // • Reserving less than the current capacity is a no-op
        //
        try {
            vector.reserve(1);
        } catch ( ... ) {
            XCTFail();
        }

        XCTAssertEqual( vector.capacity(), expected_capacity );
        XCTAssertEqual( vector.available(), vector.capacity() );
        XCTAssertEqual( vector.size(), 0 );

        XCTAssertEqual( ref.offset, 2*atom_header_length );
    }
    catch ( ... )
    {
        XCTFail();
    }
}

- (void)testPushBack {

    try
    {
        auto contents_length = uint32_t{ 1024 };
        auto contents        = std::make_unique<uint8_t[]>(contents_length);
        auto dataIt          = prepare_layout(contents.get(), 0, contents_length);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        auto ref    = VectorRef<int>{ };
        auto vector = Vector<int>{ dataIt, ref };

        XCTAssertEqual( vector.size(), 0 );
        XCTAssertTrue( vector.empty() );
        XCTAssertEqual( ref.offset, 0 );

        try {
            vector.push_back(34);
        } catch ( ... ) {
            XCTFail();
        }

        XCTAssertEqual( vector.size(), 1 );
        XCTAssertEqual( vector[0], 34 );
        XCTAssertEqual( vector.at(0), 34 );
        XCTAssertEqual( vector.front(), 34 );
        XCTAssertEqual( vector.back(), 34 );

        for ( auto val : vector )
        {
            XCTAssertEqual( val, 34 );
        }

        auto eraseIt = vector.erase( vector.cbegin() );

        XCTAssertEqual( vector.size(), 0 );
        XCTAssertTrue( vector.empty() );
        XCTAssertEqual( eraseIt, vector.cbegin() );
        XCTAssertEqual( eraseIt, vector.cend() );
    }
    catch ( ... )
    {
        XCTFail();
    }
}

- (void)testAssign {

    try
    {
        auto contents_length = uint32_t{ 1024 };
        auto contents        = std::make_unique<uint8_t[]>(contents_length);
        auto dataIt          = prepare_layout(contents.get(), 0, contents_length);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        auto ref    = VectorRef<int>{ };
        auto vector = Vector<int>{ dataIt, ref };

        try {
            vector.assign({ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 });
        } catch ( ... ) {
            XCTFail();
        }

        XCTAssertEqual( vector.size(), 17 );
        XCTAssertEqual( vector.capacity(), 20 );

        auto expected_value = 0;

        for ( auto val : vector )
        {
            XCTAssertEqual( val, expected_value++ );
        }

        vector.pop_back();

        XCTAssertEqual( vector.size(), 16 );
        XCTAssertEqual( vector.capacity(), 20 );

        expected_value = 0;

        for ( auto val : vector )
        {
            XCTAssertEqual( val, expected_value++ );
        }

        vector.erase( vector.cbegin() + 10 );

        XCTAssertEqual( vector.size(), 15 );
        XCTAssertEqual( vector[9], 9 );
        XCTAssertEqual( vector[10], 11 );

        vector.erase( vector.cbegin() + 5, vector.cbegin() + 12 );

        XCTAssertEqual( vector.size(), 8 );
        XCTAssertEqual( vector[4], 4 );
        XCTAssertEqual( vector[5], 13 );

        try {
            vector.assign({ 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7 });
        } catch ( ... ) {
            XCTFail();
        }

        XCTAssertEqual( vector.size(), 11 );

        expected_value = 17;

        for ( auto val : vector )
        {
            XCTAssertEqual( val, expected_value-- );
        }

        vector.assign({});

        XCTAssertTrue( vector.empty() );
        XCTAssertEqual( vector.capacity(), 20 );
    }
    catch ( ... )
    {
        XCTFail();
    }
}

- (void)testInsert {

    try
    {
        auto contents_length = uint32_t{ 1024 };
        auto contents        = std::make_unique<uint8_t[]>(contents_length);
        auto dataIt          = prepare_layout(contents.get(), 0, contents_length);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        auto ref    = VectorRef<int>{ };
        auto vector = Vector<int>{ dataIt, ref };

        try {
            vector.assign({ 0, 1, 2, 3, 14, 15, 16 });
        } catch ( ... ) {
            XCTFail();
        }

        XCTAssertEqual( vector.size(), 7 );
        XCTAssertEqual( vector.capacity(), 8 );

        auto insertIt = vector.end();

        try {
            insertIt = vector.insert( vector.cbegin() + 4, { 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 });
        } catch ( ... ) {
            XCTFail();
        }

        XCTAssertEqual( insertIt, vector.begin() + 4 );
        XCTAssertEqual( vector.size(), 17 );
        XCTAssertEqual( vector.capacity(), 20 );

        auto expected_value = 0;

        for ( auto val : vector )
        {
            XCTAssertEqual( val, expected_value++ );
        }

        try {
            insertIt = vector.insert(vector.cend(), 17);
        } catch ( ... ) {
            XCTFail();
        }

        XCTAssertEqual( insertIt, std::prev(vector.end()) );
        XCTAssertEqual( vector.size(), 18 );
        XCTAssertEqual( vector.capacity(), 20 );

        expected_value = 0;

        for ( auto val : vector )
        {
            XCTAssertEqual( val, expected_value++ );
        }

        try {
            insertIt = vector.insert(vector.cbegin() + 3, {});
        } catch ( ... ) {
            XCTFail();
        }

        XCTAssertEqual( insertIt, vector.begin() + 3 );
        XCTAssertEqual( vector.size(), 18 );
        XCTAssertEqual( vector.capacity(), 20 );

        expected_value = 0;

        for ( auto val : vector )
        {
            XCTAssertEqual( val, expected_value++ );
        }

        try {
            insertIt = vector.insert(vector.cend(), 0, 18);
        } catch ( ... ) {
            XCTFail();
        }

        XCTAssertEqual( insertIt, vector.end() );
        XCTAssertEqual( vector.size(), 18 );
        XCTAssertEqual( vector.capacity(), 20 );

        expected_value = 0;

        for ( auto val : vector )
        {
            XCTAssertEqual( val, expected_value++ );
        }

        // • Test that erasing the end is a no-op
        //
        vector.erase( vector.cend() );

        XCTAssertEqual( vector.size(), 18 );
        XCTAssertEqual( vector.capacity(), 20 );

        expected_value = 0;

        for ( auto val : vector )
        {
            XCTAssertEqual( val, expected_value++ );
        }
    }
    catch ( ... )
    {
        XCTFail();
    }
}

@end
