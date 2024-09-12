//
//  Composition.h
//
//  Copyright © 2024 Robert Guequierre. All rights reserved.
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
@property (nonnull, nonatomic, readonly) id<MTLBuffer> patternBuffer;
@property (nonatomic, readonly) NSInteger instanceCount;
@property (nonatomic, readonly) simd_uint2 aspectRatio;

@end
