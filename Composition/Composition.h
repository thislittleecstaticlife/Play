//
//  Composition.h
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

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

//===------------------------------------------------------------------------===
//
#pragma mark - Composition Declaration
//
//===------------------------------------------------------------------------===

@interface Composition : NSObject

// • Initialization
//
- (nullable instancetype)initWithDevice:(nonnull id<MTLDevice>)device;

// • Properties
//
@property (nonnull, nonatomic, readonly) id<MTLBuffer> gradientBuffer;
@property (nonatomic, readonly) NSInteger gradientCount;
@property (nonatomic, readonly) NSInteger maxIntervalCount;
@property (nonatomic, readonly) simd_uint2 aspectRatio;

@end
