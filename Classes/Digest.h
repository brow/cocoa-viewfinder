//
//  Digest.h
//  CameraTest
//
//  Created by Tom Brow on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrayscaleRawImage.h"
#import "DigestUtilities.h"

@interface Digest : NSObject {
	uint width, height, diagonal;
	uint *px0, *py0, *pu0, *pu1, *pv0, *pv1;
	CGPoint *corners;
}

@property (readonly) uint width;
@property (readonly) uint height;
@property (readonly) UIImage *debugImage;
@property (readonly) CGPoint *corners;

-(id)initWithGrayscaleRawImage:(GrayscaleRawImage *)rawImage smoothingBuffer:(void *)buffer;
- (id)initWithWidth:(uint)aWidth Height:(uint)aHeight;
+ (Digest *)digestWithCGImage:(CGImageRef)cgImage imageBuffer:(void *)imageBuffer smoothingBuffer:(void *)smoothingBuffer;
+ (Digest *)digestWithSmoothedGrayscaleCGImage:(CGImageRef)cgImage imageBuffer:(void *)imageBuffer;
- (SimilarityTransform)alignWithDigest:(Digest *)other;
- (SimilarityTransform)alignWithDigest:(Digest *)other confidence:(uint *)confidence;
+ (uint) maxConfidence;

@end
