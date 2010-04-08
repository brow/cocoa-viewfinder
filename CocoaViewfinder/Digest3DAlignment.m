//
//  Digest3DAlignment.m
//  CameraTest
//
//  Created by Tom Brow on 11/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Digest3DAlignment.h"
#import "CLMatrix3x3.h"
#import "Utility.h"
#import "CLConversions.h"

#define SEARCH_RADIUS_3D 0.2
#define EPSILON (1e-9)

void imagePointsToVectors(CLVector vectors[], const CGPoint points[], uint len, CGSize resolution);
void rotateVectors(CLVector dst[], CLVector src[], uint len, CATransform3D rotation);
CATransform3D CATransform3DZero();

@implementation Digest (Alignment3D)

- (CATransform3D) align3DWithDigest:(Digest *)other estimate:(CATransform3D)estimate confidence:(uint *)confidence {
	
	/* Convert 2D corner points to 3D corner vectors in camera space. */
	CGSize resolution = CGSizeMake(width, height);
	CLVector cornerVectorsP[NUM_CORNERS]; 
	CLVector cornerVectorsQ[NUM_CORNERS];
	imagePointsToVectors(cornerVectorsP, corners, NUM_CORNERS, resolution);
	imagePointsToVectors(cornerVectorsQ, other->corners, NUM_CORNERS, resolution);
	
	/* Find correspondences between vectors using proximity. */
	CLVector matchedVectorsP[NUM_CORNERS];
	CLVector matchedVectorsQ[NUM_CORNERS];
	uint numCorrespondences = findCorrespondences(cornerVectorsP, cornerVectorsQ, matchedVectorsP, matchedVectorsQ, estimate);
	if (confidence) *confidence = numCorrespondences;
	
	if (numCorrespondences < 5) {
		if (confidence) *confidence = 0;
		return CATransform3DZero();
	}
	else {
		CATransform3D alignment = alignCorners3D(matchedVectorsP, matchedVectorsQ, numCorrespondences);
		if (confidence && CATransform3DEqualToTransform(alignment, CATransform3DZero()))
			*confidence = 0;
		return alignment;
	}
}

@end

void imagePointsToVectors(CLVector vectors[], const CGPoint points[], uint len, CGSize resolution) {
	for (int i = 0; i < len; i++) {
		CLVector vector = rasterToCamSpace(points[i], FOCAL_LENGTH, resolution);
		vectors[i] = CLVectorNormalize(vector);
	}
}

void rotateVectors(CLVector dst[], CLVector src[], uint len, CATransform3D rotation) {
	for (int i = 0; i < len; i++) {
		dst[i] = CLVectorApplyCATransform3D(rotation, src[i]);
	}
}

CATransform3D CATransform3DZero() {
	CATransform3D zero = {	0, 0, 0, 0,
							0, 0, 0, 0,
							0, 0, 0, 0,
							0, 0, 0, 0	};
	return zero;
}

uint findCorrespondences(CLVector vectorsP[], CLVector vectorsQ[], 
						 CLVector matchedVectorsP[], CLVector matchedVectorsQ[],
						 CATransform3D transform) 
{
	/* Use estimated camera rotation to bring corner vectors into approximate alignment. */
	CLVector rotatedVectorsP[NUM_CORNERS];
	rotateVectors(rotatedVectorsP, vectorsP, NUM_CORNERS, transform);
	
	/* Match corners by proximity. */
	int numCorrespondences = 0;
	for (uint i = 0; i < NUM_CORNERS; i++) {
		float shortestDistance = FLT_MAX;
		CLVector bestMatch;
		for (uint j = 0; j < NUM_CORNERS; j++) {
			float distance = CLVectorAngle(rotatedVectorsP[i], vectorsQ[j]);
			if (distance < shortestDistance) {
				shortestDistance = distance;
				bestMatch = vectorsQ[j];
			}
		}
		if (shortestDistance < SEARCH_RADIUS_3D) {
			matchedVectorsP[numCorrespondences] = vectorsP[i];
			matchedVectorsQ[numCorrespondences] = bestMatch;
			numCorrespondences++;
		}
	}
	
	return numCorrespondences;
}

CATransform3D alignCorners3D(CLVector vectorsL[], CLVector vectorsR[], uint len) {
	
	/* Calculate a symmetric matrix M for the two vector sets. */
	CLMatrix3x3 m = CLMatrix3x3Zero();
	for (int i = 0; i < len; i++) {
		m.m11 += vectorsR[i].x * vectorsL[i].x;
		m.m12 += vectorsR[i].x * vectorsL[i].y;
		m.m13 += vectorsR[i].x * vectorsL[i].z;
		m.m21 += vectorsR[i].y * vectorsL[i].x;
		m.m22 += vectorsR[i].y * vectorsL[i].y;
		m.m23 += vectorsR[i].y * vectorsL[i].z;
		m.m31 += vectorsR[i].z * vectorsL[i].x;
		m.m32 += vectorsR[i].z * vectorsL[i].y;
		m.m33 += vectorsR[i].z * vectorsL[i].z;
	}
	if (CLMatrix3x3Determinant(m) < EPSILON)
		return CATransform3DZero();
	
	/* Find Mtranspose*M. */
	CLMatrix3x3 mt = CLMatrix3x3Transpose(m);
	CLMatrix3x3 mtm = CLMatrix3x3Multiply(mt, m);
	
	/* Find rotation R = U = M(MtransposeM)^(-1/2). */
	double l[3];
	CLVector u[3];
	CLMatrix3x3 u1u1t, u2u2t, u3u3t, sInverted, r;
	CLMatrix3x3SymmetricEigenvectors(mtm, l, u);
	if (l[0] < EPSILON || l[1] < EPSILON || l[2] < EPSILON)
		return CATransform3DZero();
	u1u1t = CLMatrix3x1Multiply1x3(u[0], u[0]);
	u2u2t = CLMatrix3x1Multiply1x3(u[1], u[1]);
	u3u3t = CLMatrix3x1Multiply1x3(u[2], u[2]);
	u1u1t = CLMatrix3x3MultiplyScalar(u1u1t, 1/sqrt(l[0]));
	u2u2t = CLMatrix3x3MultiplyScalar(u2u2t, 1/sqrt(l[1]));
	u3u3t = CLMatrix3x3MultiplyScalar(u3u3t, 1/sqrt(l[2]));
	sInverted = CLMatrix3x3Add(u1u1t, u2u2t);
	sInverted = CLMatrix3x3Add(sInverted, u3u3t);
	r = CLMatrix3x3Multiply(m, sInverted);
	
	return CLMatrix3x3ToCATransform3D(r);
}
