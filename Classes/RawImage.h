//
//  RawImage.h
//  CameraTest
//
//  Created by Tom Brow on 8/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface RawImage : NSObject {
	uint width;
	uint height;
	void *pixels;
	bool ownBuffer;
}

@property (readonly) void *pixels;
@property (readonly) uint width;
@property (readonly) uint height;

-(id)initWithWidth:(uint)aWidth height:(uint)aHeight buffer:(void *)buffer;
- (id)initWithCGImage:(CGImageRef)cgImage buffer:(void *)buffer;
- (UIImage *) UIImage;

- (CGImageRef) CGImage;
- (int) numChannels;
- (CGColorSpaceRef) createColorSpace;
- (CGBitmapInfo) bitmapInfo;

@end
