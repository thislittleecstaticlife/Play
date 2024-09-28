//
//  AtomTests.mm
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
#import <Data/Atom.hpp>

#import <vector>

using namespace data;

//===------------------------------------------------------------------------===
#pragma mark - AtomTests
//===------------------------------------------------------------------------===

@interface AtomTests : XCTestCase

@end

//===------------------------------------------------------------------------===
#pragma mark - AtomTests Implementation
//===------------------------------------------------------------------------===

@implementation AtomTests

- (void)testStaticData {

    try
    {
        const auto contents = std::vector<uint8_t>{ {

            // Atom: length, identifier, previous, user_defined
            16,0,0,0,   'c','r','s','r',     0,0,0,0,   0,0,0,0,
            32,0,0,0,   'e','e','r','f',    16,0,0,0,   0,0,0,0,
                0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
            48,0,0,0,   'c','o','l','a',    32,0,0,0,   0,0,0,0,
                0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
                0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
            16,0,0,0,   ' ','d','n','e',    48,0,0,0,   0,0,0,0,
        } };

        const auto contents_length = static_cast<uint32_t>( contents.size() );

        XCTAssertTrue( validate_layout(contents.data(), contents_length) );

        auto rsrcIt = resource_iterator(contents.data(), contents_length);

        XCTAssertEqual( rsrcIt->identifier, AtomID::resource );
        XCTAssertEqual( rsrcIt->length, 16 );
        XCTAssertTrue( rsrcIt.empty() );

        auto freeIt = std::next(rsrcIt);

        XCTAssertEqual( freeIt->identifier, AtomID::free );
        XCTAssertEqual( freeIt->length, 32 );
        XCTAssertEqual( freeIt->previous, rsrcIt->length );
        XCTAssertFalse( freeIt.empty() );

        auto allocIt = std::next(freeIt);

        XCTAssertEqual( allocIt->identifier, AtomID::allocation );
        XCTAssertEqual( allocIt->length, 48 );
        XCTAssertEqual( allocIt->previous, 32 );
        XCTAssertEqual( allocIt->previous, freeIt->length );
        XCTAssertFalse( allocIt.empty() );

        auto endIt = end_iterator(contents.data(), contents_length);

        XCTAssertEqual( std::next(allocIt), endIt );
        XCTAssertEqual( endIt->identifier, AtomID::end );
        XCTAssertEqual( endIt->length, atom_header_length );
        XCTAssertEqual( endIt->previous, allocIt->length );
        XCTAssertTrue( endIt.empty() );

        XCTAssertEqual( rsrcIt, std::prev(freeIt) );
        XCTAssertEqual( freeIt, std::prev(allocIt) );
        XCTAssertEqual( allocIt, std::prev(endIt) );
    }
    catch ( ... )
    {
        XCTFail();
    }
}

- (void)testDefaultLayout {

    try
    {
        auto contents_length = uint32_t{ 1024 };
        auto contents        = std::make_unique<uint8_t[]>(contents_length);

        auto rsrcIt = prepare_resource(contents.get(), contents_length);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        XCTAssertEqual( rsrcIt->identifier, AtomID::resource );
        XCTAssertEqual( rsrcIt->length, 16 );
        XCTAssertTrue( rsrcIt.empty() );

        auto freeIt = std::next(rsrcIt);

        XCTAssertEqual( freeIt->identifier, AtomID::free );
        XCTAssertEqual( freeIt->length, contents_length - 2*atom_header_length );
        XCTAssertEqual( freeIt->previous, rsrcIt->length );
        XCTAssertFalse( freeIt.empty() );

        auto endIt = end_iterator(contents.get(), contents_length);

        XCTAssertEqual( std::next(freeIt), endIt );
        XCTAssertEqual( endIt->identifier, AtomID::end );
        XCTAssertEqual( endIt->length, atom_header_length );
        XCTAssertEqual( endIt->previous, freeIt->length );
        XCTAssertTrue( endIt.empty() );

        XCTAssertEqual( rsrcIt, std::prev(freeIt) );
        XCTAssertEqual( freeIt, std::prev(endIt) );
    }
    catch ( ... )
    {
        XCTFail();
    }
}

- (void)testMinimumLayout {

    try
    {
        auto contents_length = uint32_t{ 2*atom_header_length };
        auto contents        = std::make_unique<uint8_t[]>(contents_length);

        auto rsrcIt = prepare_resource(contents.get(), contents_length);

        XCTAssertTrue( validate_layout(contents.get(), contents_length) );

        XCTAssertEqual( rsrcIt->identifier, AtomID::resource );
        XCTAssertEqual( rsrcIt->length, 16 );
        XCTAssertTrue( rsrcIt.empty() );

        auto endIt = end_iterator(contents.get(), contents_length);

        XCTAssertEqual( std::next(rsrcIt), endIt );
        XCTAssertEqual( endIt->identifier, AtomID::end );
        XCTAssertEqual( endIt->length, atom_header_length );
        XCTAssertEqual( endIt->previous, rsrcIt->length );
        XCTAssertTrue( endIt.empty() );

        XCTAssertEqual( rsrcIt, std::prev(endIt) );
    }
    catch ( ... )
    {
        XCTFail();
    }
}

@end
