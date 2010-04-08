//
//  Digest3DAlignment.h
//  CameraTest
//
//  Created by Tom Brow on 11/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Digest.h"
#import "CLVector.h"

#define NUM_CORNERS 28
#define FOCAL_LENGTH 2.81

@interface Digest(Alignment3D)

- (CATransform3D) align3DWithDigest:(Digest *)other estimate:(CATransform3D)estimate confidence:(uint *)confidence;

@end

CATransform3D alignCorners3D(CLVector vectorsL[], CLVector vectorsR[], uint len);
uint findCorrespondences(CLVector vectorsP[], CLVector VectorsQ[], CLVector matchedVectorsP[], CLVector matchedVectorsQ[], CATransform3D transform);