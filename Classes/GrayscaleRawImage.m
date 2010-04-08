//
//  GrayscaleRawImage.m
//  CameraTest
//
//  Created by Tom Brow on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GrayscaleRawImage.h"

#define AT(X,Y) ((X)+(Y)*w)

@implementation GrayscaleRawImage

- (int) numChannels { return 1; }
- (CGColorSpaceRef) createColorSpace { return CGColorSpaceCreateDeviceGray(); }
- (CGBitmapInfo) bitmapInfo { return kCGImageAlphaNone; }

- (GrayscaleRawImage *) smoothedImageInBuffer:(void *)buffer {
	GrayscaleRawImage *smoothed = [[[GrayscaleRawImage alloc] initWithWidth:width height:height buffer:buffer] autorelease];
	unsigned char *inPixels = pixels;
	unsigned char *smoothedPixels = smoothed.pixels;
	int w = width;
	int radius = 1;
	float weight = 1/9.0;
	
	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			uint smoothedPixel = 0;
			for (int u = x-radius; u <= x+radius; u++) {
				int uClamped = MAX(MIN(u,(int)(width-1)), 0);
				for (int v = y-radius; v <= y+radius; v++) {
					int vClamped = MAX(MIN(v,(int)(height-1)), 0);
					smoothedPixel += inPixels[AT(uClamped,vClamped)];
				}
			}
			smoothedPixels[AT(x,y)] = smoothedPixel * weight;
		}
	}
	
	return smoothed;
}

//- (GrayscaleRawImage *) smoothedImage {
//	/* Wow, this implementation is slower _and_ sucks more. */
//	
//	CGImageRef originalImage = [super CGImage];
//	CGRect imageRect = CGRectMake(0, 0, width, height);
//	
//	/* Set up output context. */
//	GrayscaleRawImage *smoothed = [[[GrayscaleRawImage alloc] initWithWidth:width Height:height] autorelease];
//	CGColorSpaceRef colorSpace = [self createColorSpace];
//	CGContextRef context = CGBitmapContextCreate(smoothed.pixels, smoothed.width, smoothed.height, 
//												 8								/* bits per component*/, 
//												 width * [self numChannels], 	/* bytes per row */
//												 colorSpace,
//												 [self bitmapInfo]);
//	CGContextSetInterpolationQuality(context, kCGInterpolationLow);
//	CGContextClearRect(context, imageRect);
//	CGContextSetBlendMode(context, kCGBlendModePlusLighter);
//	
//	/* Draw image multiple times to blur. */
//	int radius = 1;
//	float weight = 1/9.0;
//	CGContextSetAlpha(context, weight);
//	for (int u = -radius; u <= radius; u++) {
//		for (int v = -radius; v <= radius; v++) {
//			CGContextSaveGState(context);
//			CGContextTranslateCTM(context, u, v);
//			CGContextDrawImage(context, imageRect, originalImage);
//			CGContextRestoreGState(context);
//		}
//	}
////	for (int i = 0; i < 2; i++)
////		CGContextDrawImage(context, imageRect, originalImage);
//	
//	CGColorSpaceRelease(colorSpace);
//	CGContextRelease(context);
//	CGImageRelease(originalImage);
//	
//	return smoothed;
//}

@end
