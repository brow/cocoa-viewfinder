//
//  DigestUtilities.m
//  CameraTest
//
//  Created by Tom Brow on 11/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DigestUtilities.h"
#import "CLMatrix2x2.h"

#define EPSILON (10e-9)

inline extern uint sq_u(uint x) {
	return x*x;
}

inline extern int sq_i(int x) {
	return x*x;
}

inline extern float sq_f(float x) {
	return x*x;
}

int alignProjections(uint pd0[], uint pd1[], uint qd0[], uint qd1[], uint length, int searchRadius) {
	assert(searchRadius > 0 && searchRadius < length);
	
	/* Find shift that minimizes sum square difference between projections pd0 and qd0. */
	/* Use pd1 and qd1 as weights if provided. */
	float bestError = FLT_MAX;
	int bestDelta = 0;
	for (int delta = -searchRadius; delta <= searchRadius; delta++) {
		float error = 0;
		uint start = MAX(0, -delta);
		uint end = MIN(length, length - delta);
		if (pd1 && qd1) {
			/* Weighted sum square difference. */
			for (uint i = start; i < end; i++)
				error += sq_f((int)pd0[i]*(int)qd1[i+delta]-(int)qd0[i+delta]*(int)pd1[i]);
		}
		else {
			/* Unweighted sum square difference. */
			for (uint i = start; i < end; i++)
				error += sq_f((int)pd0[i]-(int)qd0[i+delta]);
		}
		
		if (error < bestError) {
			bestError = error;
			bestDelta = delta;
		}
	}
	
	return bestDelta;
}

SimilarityTransform alignCorners(const CGPoint cornersL[], const CGPoint cornersR[], uint len, CGPoint imageCenter) {
	/* Find centroids for corner sets. */
	CGPoint centroidL, centroidR;
	centroidL = centroidOfPoints((CGPoint *)cornersL, len);
	centroidR = centroidOfPoints((CGPoint *)cornersR, len);
	
	/* Convert corner sets to vector sets with origins at respective centroids. */
	CGPoint vectorsL[len], vectorsR[len];
	pointsToVectors(cornersL, vectorsL, centroidL, len);
	pointsToVectors(cornersR, vectorsR, centroidR, len);
	
	/* Calculate a symmetric matrix M for the two vector sets. */
	double m[4];
	m[0] = m[1] = m[2] = m[3] = 0;
	for (int i = 0; i < len; i++) {
		m[0] += vectorsR[i].x * vectorsL[i].x;
		m[1] += vectorsR[i].x * vectorsL[i].y;
		m[2] += vectorsR[i].y * vectorsL[i].x;
		m[3] += vectorsR[i].y * vectorsL[i].y;
	}
	if (m[0]*m[3]-m[1]*m[2] < EPSILON)
		return SimilarityTransformZero();
	
	/* Find Mtranspose*M. */
	double mt[4], mtm[4];
	CLMatrix2x2Transpose(m, mt);
	CLMatrix2x2Multiply(mt, m, mtm);
	
	/* Find rotation R = U = M(MtransposeM)^(-1/2). */
	double l1, l2, u1[2], u2[2], u1u1t[4], u2u2t[4], sInverted[4], r[4];
	CLMatrix2x2Eigenvectors(mtm, &l1, &l2, u1, u2);
	if (l1 <= 0 || l2 <= 0)
		return SimilarityTransformZero();
	CLMatrix2x1Multiply1x2(u1, u1, u1u1t); 
	CLMatrix2x1Multiply1x2(u2, u2, u2u2t);
	CLMatrix2x2MultiplyScalar(u1u1t, 1/sqrt(l1), u1u1t);
	CLMatrix2x2MultiplyScalar(u2u2t, 1/sqrt(l2), u2u2t);
	CLMatrix2x2Add(u1u1t, u2u2t, sInverted);
	CLMatrix2x2Multiply(m, sInverted, r);
	
	/* Find translation r0. */
	CGPoint r0, centroidLrotated;
	centroidLrotated.x = centroidL.x - imageCenter.x;
	centroidLrotated.y = centroidL.y - imageCenter.y;
	centroidLrotated = CLMatrix2x2Transform(r, centroidLrotated);
	centroidLrotated.x += imageCenter.x;
	centroidLrotated.y += imageCenter.y;
	r0.x = centroidR.x - centroidLrotated.x;
	r0.y = centroidR.y - centroidLrotated.y;
	
	/* Express rotation R as a rotated unit vector. */
	double v[2] = {1, 0}, vRotated[2];
	CLMatrix2x2Multiply2x1(r, v, vRotated);
	
	SimilarityTransform ret;
	ret.a = vRotated[0];
	ret.b = vRotated[1];
	ret.x = r0.x;
	ret.y = r0.y;
	return ret;
}

CGPoint centroidOfPoints(const CGPoint *points, uint len) {
	CGPoint centroid = CGPointZero;
	for (uint i = 0; i < len; i++) {
		centroid.x += points[i].x;
		centroid.y += points[i].y;
	}
	centroid.x /= len;
	centroid.y /= len;
	return centroid;
}

void pointsToVectors(const CGPoint *srcPoints, CGPoint *dstVectors, CGPoint origin, uint len) {
	for (uint i = 0; i < len; i++) {
		dstVectors[i].x = srcPoints[i].x - origin.x;
		dstVectors[i].y = srcPoints[i].y - origin.y;
	}
}

uint insertSorted(int value, int *array, uint len) {
	// Find insertion point
	int valueIndex;
	for (int i = 0; i < len; i++) {
		if (array[i] >= value) 
			continue;
		else {
			valueIndex = i;
			break;
		}
		assert(false); //should always find insertion point
	}
	
	// Shift values after insertion point
	for (int i = len-1; i > valueIndex; i--)
		array[i] = array[i-1];
	
	// Insert value
	array[valueIndex] = value;
	return valueIndex;
}

void insert(CGPoint value, CGPoint *array, uint index, uint len) {
	for (int i = len-1; i > index; i--)
		array[i] = array[i-1];
	array[index] = value;
}

SimilarityTransform SimilarityTransformZero() {
	SimilarityTransform zero = {0, 0, 0, 0};
	return zero;
}
