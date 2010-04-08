//
//  Digest.m
//  CameraTest
//
//  Created by Tom Brow on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Digest.h"
#import "CLMatrix2x2.h"

#define ALIGNMENT_SEARCH_RADIUS 40
#define CORNER_SEARCH_RADIUS 4.8
#define NUM_CORNERS 28

#define AT_C(X,Y,C) (((X)*4)+((Y)*width*4)+(C))
#define AT(X,Y) ((X)+(Y)*width)

inline  uint sq_u(uint x);

@interface Digest ()
- (void) computeProjections:(unsigned char *)pixels;
- (void) computeCorners:(unsigned char *)pixels;
@end

@implementation Digest

@synthesize width, height, corners;

-(id)initWithSmoothedGrayscaleRawImage:(GrayscaleRawImage *)smoothedImage {
	if (self = [super init]) {
		width = smoothedImage.width;
		height = smoothedImage.height;
		diagonal = (((width-1) + (height-1)) / 2) + 1;
		
		px0 = malloc(height * sizeof(uint));
		py0 = malloc(width * sizeof(uint));
		pu0 = malloc(diagonal * sizeof(uint));
		pu1 = malloc(diagonal * sizeof(uint));
		pv0 = malloc(diagonal * sizeof(uint));
		pv1 = malloc(diagonal * sizeof(uint));
		corners = malloc(NUM_CORNERS * sizeof(CGPoint));
		
		[self computeProjections:smoothedImage.pixels];
		[self computeCorners:smoothedImage.pixels];
	}
	return self;
}

-(id)initWithGrayscaleRawImage:(GrayscaleRawImage *)rawImage smoothingBuffer:(void *)smoothingBuffer {
	GrayscaleRawImage *smoothedImage = [rawImage smoothedImageInBuffer:smoothingBuffer];
	return [self initWithSmoothedGrayscaleRawImage:smoothedImage];
}

- (id) initWithWidth:(uint)aWidth Height:(uint)aHeight {
	if (self = [super init]) {
		width = aWidth;
		height = aHeight;
		diagonal = (((width-1) + (height-1)) / 2) + 1;
		
		px0 = malloc(height * sizeof(uint));
		py0 = malloc(width * sizeof(uint));
		pu0 = malloc(diagonal * sizeof(uint));
		pu1 = malloc(diagonal * sizeof(uint));
		pv0 = malloc(diagonal * sizeof(uint));
		pv1 = malloc(diagonal * sizeof(uint));
		corners = malloc(NUM_CORNERS * sizeof(CGPoint));
	}
	return self;
}

- (void)dealloc {
	free(px0);
	free(py0);
	free(pu0);
	free(pu1);
	free(pv0);
	free(pv1);
	free(corners);
    [super dealloc];
}

+ (Digest *)digestWithCGImage:(CGImageRef)cgImage imageBuffer:(void *)imageBuffer smoothingBuffer:(void *)smoothingBuffer {
	GrayscaleRawImage *rawImage = [[GrayscaleRawImage alloc] initWithCGImage:cgImage buffer:imageBuffer];	
	Digest *ret = [[[Digest alloc] initWithGrayscaleRawImage:rawImage smoothingBuffer:smoothingBuffer] autorelease];
	[rawImage release];
	return ret;
}

+ (Digest *)digestWithSmoothedGrayscaleCGImage:(CGImageRef)cgImage imageBuffer:(void *)imageBuffer {
	GrayscaleRawImage *rawImage = [[GrayscaleRawImage alloc] initWithCGImage:cgImage buffer:imageBuffer];	
	Digest *ret = [[[Digest alloc] initWithSmoothedGrayscaleRawImage:rawImage] autorelease];
	[rawImage release];
	return ret;
}

+ (uint) maxConfidence {
	return NUM_CORNERS;
}

- (UIImage *) debugImage {
	RawImage *debugImage = [[[RawImage alloc] initWithWidth:width Height:height] autorelease];
	unsigned char *debugPixels = debugImage.pixels;
	
	/* Render corners as points. */
	for (int corner = 0; corner < NUM_CORNERS; corner++) {
		uint x = corners[corner].x;
		uint y = corners[corner].y;
		debugPixels[AT_C(x,y,1)] = 255;
	}
	
	return [debugImage UIImage];
}

- (SimilarityTransform) alignWithDigest:(Digest *)other {
	return [self alignWithDigest:other confidence:nil];
}

- (SimilarityTransform) alignWithDigest:(Digest *)other confidence:(uint *)confidence {
	assert(self->width == other->width && self->height == other->height);
		
	/* Align edge projections to estimate translation. */
	float deltaX = alignProjections(self->py0, NULL, other->py0, NULL, width, ALIGNMENT_SEARCH_RADIUS);
	float deltaY = alignProjections(self->px0, NULL, other->px0, NULL, height, ALIGNMENT_SEARCH_RADIUS);	
	float deltaU = alignProjections(self->pu0, self->pu1, other->pu0, other->pu1, diagonal, ALIGNMENT_SEARCH_RADIUS);
	float deltaV = alignProjections(self->pv0, self->pv1, other->pv0, other->pv1, diagonal, ALIGNMENT_SEARCH_RADIUS);
	float avgDeltaX = (deltaX + deltaU + deltaV) / 2;
	float avgDeltaY = (deltaY + deltaU - deltaV) / 2;
	
	/* Shift corners by estimated translation. */
	CGPoint shiftedCorners[NUM_CORNERS];
	for (int i = 0; i < NUM_CORNERS; i++) {
		shiftedCorners[i].x = corners[i].x + avgDeltaX;
		shiftedCorners[i].y = corners[i].y + avgDeltaY;
	}
	
	/* Find corner correspondences. TODO: replace O(n^2) search. */
	CGPoint matchedCornersP[NUM_CORNERS];
	CGPoint matchedCornersQ[NUM_CORNERS];
	int numCorrespondences = 0;
	float sqCornerSearchRadius = pow(CORNER_SEARCH_RADIUS, 2);
	for (uint i = 0; i < NUM_CORNERS; i++) {
		float shortestSqDistance = FLT_MAX;
		CGPoint bestMatch = CGPointZero;
		for (uint j = 0; j < NUM_CORNERS; j++) {
			float sqDistance =	powf(shiftedCorners[i].x - other->corners[j].x, 2) 
			+ powf(shiftedCorners[i].y - other->corners[j].y, 2);
			if (sqDistance < shortestSqDistance) {
				shortestSqDistance = sqDistance;
				bestMatch = other->corners[j];
			}
		}
		if (shortestSqDistance < sqCornerSearchRadius) {
			matchedCornersP[numCorrespondences] = corners[i];
			matchedCornersQ[numCorrespondences] = bestMatch;
			numCorrespondences++;
		}
	}
	
	/* Find least-squares transformation that relates corresponding corners. */
	SimilarityTransform ret = {1, 0, avgDeltaX, avgDeltaY};
	if (numCorrespondences > 6)
		ret = alignCorners(matchedCornersP, matchedCornersQ, numCorrespondences, CGPointMake((float)width/2, (float)height/2));
	if (confidence) {
		if (ret.a == 0 && ret.b == 0)
			*confidence = 0;
		else
			*confidence = numCorrespondences;
	}
	
	return ret;
}

- (void) computeProjections:(unsigned char *)pixels {
	/* Clear projection arrays. */
	for (int i = 0; i < height; i++)
		px0[i] = 0;
	for (int i = 0; i < width; i++)
		py0[i] = 0;
	for (int i = 0; i < diagonal; i++)
		pu0[i] = pu1[i] = pv0[i] = pv1[i] = 0;
	
	/* Calculate projections. */
	for (uint y = 0; y < height; y++) {
		for (uint x = 0; x < width; x++) {
			if (y > 0) {
				px0[y] += sq_u(pixels[AT(x,y)] - pixels[AT(x,y-1)]);
				if(x < width-1) {
					uint i = (x + height - y) / 2;
					pv0[i] += sq_u(pixels[AT(x,y)] - pixels[AT(x+1,y-1)]);
					pv1[i] += 1;
				}
			}
			if (x > 0) {
				py0[x] += sq_u(pixels[AT(x,y)] - pixels[AT(x-1,y)]);
				if(y > 0) {
					uint i = (x + y) / 2;
					pu0[i] += sq_u(pixels[AT(x,y)] - pixels[AT(x-1,y-1)]);
					pu1[i] += 1;
				}
			}
		}
	}
}

- (void) computeCorners:(unsigned char *)pixels {
	int bestValues[NUM_CORNERS];
	
	/* Clear corners array. */
	for (int i = 0; i < NUM_CORNERS; i++) {
		bestValues[i] = 0;
		corners[i].x = 0;
		corners[i].y = 0;
	}
	
	/* Find k strongest corners. */
	for (uint y = 1; y < height-1; y++) {
		for (uint x = 1; x < width-1; x++) {
			// Corner value = minimum second derivative over directions x, y, u, and v
			int center = 2*(int)pixels[AT(x,y)];
			int d2x = abs((int)pixels[AT(x-1,y)] + (int)pixels[AT(x+1,y)] - center);
			int d2y = abs((int)pixels[AT(x,y-1)] + (int)pixels[AT(x,y+1)] - center);
			int d2u = abs((int)pixels[AT(x-1,y-1)] + (int)pixels[AT(x+1,y+1)] - center);
			int d2v = abs((int)pixels[AT(x-1,y+1)] + (int)pixels[AT(x+1,y-1)] - center);
			int value = MIN(MIN(d2x, d2y), MIN(d2u, d2v));
			
			if (value > bestValues[NUM_CORNERS-1]) {
				uint index = insertSorted(value, bestValues, NUM_CORNERS);
				insert(CGPointMake(x,y), corners, index, NUM_CORNERS);
			}
		}
	}
}

@end

inline  uint sq_u(uint x) {
	return x*x;
}
