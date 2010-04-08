//
//  UtilityTests.m
//  CameraTest
//
//  Created by Tom Brow on 11/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UtilityTests.h"
#import "CLVector.h"
#import "Utility.h"

#define ACCURACY 0.00001
#define NUM_TRIALS 250

@implementation UtilityTests

- (void) setUp {
	srand(123);
}

- (void) testSpaceConversions {
	CGSize rasterSize = CGSizeMake(160, 213);
	for (int trial = 0; trial < NUM_TRIALS; trial++) {
		float focalLength = 0.5 + rand() * 4.0 / RAND_MAX;
		CGPoint checkPoint = CGPointMake(rand() * rasterSize.width / RAND_MAX, 
										 rand() * rasterSize.height / RAND_MAX);
		
		CLVector testVector = rasterToCamSpace(checkPoint, focalLength, rasterSize);
		testVector = CLVectorMultiplyScalar(testVector, rand()*5/RAND_MAX);
		CGPoint testPoint = camSpaceToRaster(testVector, focalLength, rasterSize);
		
		GHAssertEqualsWithAccuracy(testPoint.x, checkPoint.x, ACCURACY, nil);
		GHAssertEqualsWithAccuracy(testPoint.y, checkPoint.y, ACCURACY, nil);
	}
}

@end
