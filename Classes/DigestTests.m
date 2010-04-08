//
//  DigestTests.m
//  CameraTest
//
//  Created by Tom Brow on 11/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DigestTests.h"
#import "Digest.h"
#import "Digest3DAlignment.h"
#import "CLVector.h"
#import "CLMatrix3x3.h"
#import "Utility.h"
#import "CLConversions.h"

#define NUM_CORNERS 28
#define ACCURACY 0.000001
#define NUM_TRIALS 250

@implementation DigestTests

- (void) testFindCorners {
	UIImage *testImage = [UIImage imageNamed:@"pic_0.png"];
	Digest *digest = [Digest digestWithSmoothedGrayscaleCGImage:[testImage CGImage] imageBuffer:nil];
	CGPoint check[] = { 
		102, 176,
		102, 170,
		102, 180,
		109, 124,
		101, 170,
		71, 115,
		101, 180,
		73, 163,
		73, 164,
		77, 107,
		101, 140,
		152, 145,
		153, 146,
		122, 99,
		71, 111,
		78, 159,
		145, 160,
		71, 107,
		77, 110,
		104, 150,
		138, 80,
		77, 111,
		124, 122,
		100, 136,
		151, 140,
		101, 152,
		122, 102,
		125, 111,
	};		
	for (int i = 0; i < NUM_CORNERS; i++)
		GHAssertEquals(digest.corners[i], check[i], nil);
}

- (void) testAlignCorners {
	CGSize imageSize = CGSizeMake(160, 213);
	CGPoint imageCenter = CGPointMake(imageSize.width/2,imageSize.height/2);
	CGPoint cornersL[NUM_CORNERS], cornersR[NUM_CORNERS];
	
	for (int trial = 0; trial < NUM_TRIALS; trial++) {
		float testAngle = (float)rand() * 2*M_PI / RAND_MAX;
		CGPoint testTranslation = {rand() % 40 - 20, rand() % 40 - 20};
		
		/* Build test transform. */
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformTranslate(transform, testTranslation.x, testTranslation.y);
		transform = CGAffineTransformTranslate(transform, imageCenter.x, imageCenter.y);
		transform = CGAffineTransformRotate(transform, testAngle);
		transform = CGAffineTransformTranslate(transform, -imageCenter.x, -imageCenter.y);
		
		CGAffineTransformMakeRotation(M_PI / 180.0);
		
		/* Generate random left-side corners. */
		for (int i = 0; i < NUM_CORNERS; i++) {
			cornersL[i].x = (int)((float)rand() * imageSize.width / RAND_MAX);
			cornersL[i].y = (int)((float)rand() * imageSize.height / RAND_MAX);
		}
		
		/* Transform to right-side corners. */
		for (int i = 0; i < NUM_CORNERS; i++)
			cornersR[i] = CGPointApplyAffineTransform(cornersL[i], transform);
		
		SimilarityTransform result = alignCorners(cornersL, cornersR, NUM_CORNERS, imageCenter);
		
		[self assertDouble:testTranslation.x equalsDouble:result.x withAccuracy:0.0001];
		[self assertDouble:testTranslation.y equalsDouble:result.y withAccuracy:0.0001];
		[self assertDouble:cosf(testAngle) equalsDouble:result.a withAccuracy:0.0001];
		[self assertDouble:sinf(testAngle) equalsDouble:result.b withAccuracy:0.0001];
	}
}

- (void) testAlignCorners3D {
	CLVector vectorsL[NUM_CORNERS], vectorsR[NUM_CORNERS];
	for (int trial = 0; trial < NUM_TRIALS; trial++) {
		CATransform3D rotation = randomRotation();
		
		/* Generate random left-side corners. */
		for (int i = 0; i < NUM_CORNERS; i++)
			vectorsL[i] = randomNormalizedVector();
		
		/* Transform to right-side corners. */
		for (int i = 0; i < NUM_CORNERS; i++)
			vectorsR[i] = CLVectorApplyCATransform3D(rotation, vectorsL[i]);
		
		CATransform3D result = alignCorners3D(vectorsL, vectorsR, NUM_CORNERS);
		[self assertTransform:result equalsTransform:rotation withAccuracy:ACCURACY];
	}
}

- (void) testAlign3DWithDigest {
	CGSize imageSize = CGSizeMake(160, 213);
	CGPoint cornersL[NUM_CORNERS], cornersR[NUM_CORNERS];
	
	for (int trial = 0; trial < NUM_TRIALS; trial++) {
		CATransform3D rotation = randomRotationWithin(M_PI/4);
		
		/* Generate random left-side corners. */
		for (int i = 0; i < NUM_CORNERS; i++) {
			cornersL[i].x = (int)((float)rand() * imageSize.width / RAND_MAX);
			cornersL[i].y = (int)((float)rand() * imageSize.height / RAND_MAX);
		}
		
		/* Transform to right-side corners.*/
		for (int i = 0; i < NUM_CORNERS; i++) {
			CLVector cornerVector = rasterToCamSpace(cornersL[i], 2.81, imageSize);
			CLVector rotatedCornerVector = CLVectorApplyCATransform3D(rotation, cornerVector);
			cornersR[i] = camSpaceToRaster(rotatedCornerVector, 2.81, imageSize);
		}
		
		/* Load corner sets into digests. */
		Digest *digestL = [[[Digest alloc] initWithWidth:imageSize.width Height:imageSize.height] autorelease];
		Digest *digestR = [[[Digest alloc] initWithWidth:imageSize.width Height:imageSize.height] autorelease];
		memcpy(digestL.corners, cornersL, NUM_CORNERS * sizeof(CGPoint));
		memcpy(digestR.corners, cornersR, NUM_CORNERS * sizeof(CGPoint));
		
		/* Try aligning digests. */
		uint confidence;
		CATransform3D result = [digestL align3DWithDigest:digestR estimate:rotation confidence:&confidence];
		
		GHAssertEquals(confidence, (uint)NUM_CORNERS, nil);
		GHAssertTrue(CLMatrix3x3IsOrthonormal(CLMatrix3x3FromCATransform3D(result)), nil);
		[self assertTransform:result equalsTransform:rotation withAccuracy:ACCURACY];
	}
}

@end