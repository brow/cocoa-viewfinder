//
//  DigestUtilities.h
//  CameraTest
//
//  Created by Tom Brow on 11/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef struct {
	float a, b, x, y;
} SimilarityTransform;

SimilarityTransform SimilarityTransformZero();
int alignProjections(uint *pd0, uint *pd1, uint *qd0, uint *qd1, uint length, int searchRadius);
SimilarityTransform alignCorners(const CGPoint *cornersL, const CGPoint *cornersR, uint len, CGPoint imageCenter);
CGPoint centroidOfPoints(const CGPoint *points, uint len);
void pointsToVectors(const CGPoint *srcPoints, CGPoint *dstVectors, CGPoint origin, uint len);
uint insertSorted(int value, int *array, uint len);
void insert(CGPoint value, CGPoint *array, uint index, uint len);
