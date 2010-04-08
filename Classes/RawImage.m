//
//  RawImage.m
//  CameraTest
//
//  Created by Tom Brow on 8/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RawImage.h"


@implementation RawImage

@synthesize pixels, width, height;

- (int) numChannels { return 4; }
- (CGColorSpaceRef) createColorSpace { return CGColorSpaceCreateDeviceRGB(); }
- (CGBitmapInfo) bitmapInfo { return kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big; }

-(id)initWithWidth:(uint)aWidth height:(uint)aHeight buffer:(void *)buffer {
	if (self = [super init]) {
		width = aWidth;
		height = aHeight;
		
		if (buffer) {
			pixels = buffer;
			ownBuffer = NO;
		}
		else {
			pixels = malloc(width * height * [self numChannels]);
			ownBuffer = YES;
		}
	}
	return self;
}

- (id)initWithCGImage:(CGImageRef)cgImage buffer:(void *)buffer {
	width = CGImageGetWidth(cgImage);
	height = CGImageGetHeight(cgImage);
	if (self = [self initWithWidth:width height:height buffer:buffer]) {
		CGColorSpaceRef colorSpace = [self createColorSpace];
		CGContextRef context = CGBitmapContextCreate(pixels, width, height, 
													 8,								/* bits per component*/
													 width * [self numChannels], 	/* bytes per row */
													 colorSpace, 
													 [self bitmapInfo]);
		CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
		CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
		CGColorSpaceRelease(colorSpace);
		CGContextRelease(context);
	}
	return self;
}

- (CGImageRef) CGImage {
	CGColorSpaceRef colorSpace = [self createColorSpace];
	CGContextRef context = CGBitmapContextCreate(pixels, width, height, 
												 8								/* bits per component*/, 
												 width * [self numChannels], 	/* bytes per row */
												 colorSpace,
												 [self bitmapInfo]);
	CGImageRef cgImage = CGBitmapContextCreateImage(context);
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	return cgImage;
}

- (UIImage *) UIImage {
	CGImageRef cgImage = [self CGImage];
	UIImage *ret = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return ret;
}

- (void) dealloc {
	if (ownBuffer)
		free(pixels);
	[super dealloc];
}

@end
