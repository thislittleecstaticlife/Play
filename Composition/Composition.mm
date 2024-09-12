//
//  Composition.mm
//
//  Copyright © 2024 Robert Guequierre. All rights reserved.
//

#import "Composition.h"
#import "Pattern.hpp"

#import <numeric>

//===------------------------------------------------------------------------===
//
#pragma mark - Composition Implementation
//
//===------------------------------------------------------------------------===

@implementation Composition
{
    const Pattern* pattern;
}

//===------------------------------------------------------------------------===
#pragma mark - Initialization
//===------------------------------------------------------------------------===

- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device {

    self = [super init];

    if (nil != self) {

        // • Pattern buffer
        //
        _patternBuffer = [device newBufferWithLength:data::aligned_size<Pattern>()
                                             options:0];
        if (nil == _patternBuffer) {
            return nil;
        }

        auto pattern = static_cast<Pattern*>(_patternBuffer.contents);

        *pattern = {
            .grid_size   = { 10, 10 },
            .base_region = geometry::make_region({ 1, 1 }, { 8, 2 }),
            .offset      = { 0, 3 },
            .count       = 3
        };

        // • Aspect ratio
        //
        const auto aspect_gcd = std::gcd(pattern->grid_size.x, pattern->grid_size.y);

        _aspectRatio = {
            pattern->grid_size.x / aspect_gcd,
            pattern->grid_size.y / aspect_gcd
        };

        // • Keep a pointer
        //
        self->pattern = pattern;
    }

    return self;
}

//===------------------------------------------------------------------------===
#pragma mark - Properties
//===------------------------------------------------------------------------===

- (NSInteger)instanceCount {

    return pattern->count;
}

@end
