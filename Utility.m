#include "Utility.h"
#include <math.h>

/* 4x4 matrix transpose */
void transpose(GLfloat *dst, const GLfloat *src) {
	for (int i = 0; i < 4; i++)
		for (int j = 0; j < 4; j++)
			dst[4*i + j] = src[4*j + i];
}

/* Signed angle (-180° to 180°) between 2D vectors. */
float angle2Dsigned(const float a[2], const float b[2]) {
	return (atan2(b[1],b[0]) - atan2(a[1],a[0])) * 180 / M_PI;
}

/* Convert raster coordinates to camera space coordinates between (-1, -1/aspect, focalLength) and (1, 1/aspect, focalLength) */
CLVector rasterToCamSpace(CGPoint src, CGFloat focalLength, CGSize resolution) {
	CLVector ret;
	float aspect = resolution.width / resolution.height;
	ret.x = 2 * src.x / resolution.width - 1.0;
	ret.y = (2 * src.y / resolution.height - 1.0)  / aspect;
	ret.z = focalLength;
	return ret;
}

CGPoint camSpaceToRaster(CLVector src, CGFloat focalLength, CGSize resolution) {
	src = CLVectorMultiplyScalar(src, focalLength/src.z);
	float aspect = resolution.width / resolution.height;
	
	CGPoint ret;
	ret.x = (src.x + 1.0) * resolution.width * 0.5;
	ret.y = (src.y * aspect + 1.0) * resolution.height * 0.5;
	return ret;
}

/* Convert CA3DTransform to OpenGL matrix. */
void matrixFromCA3DTransform(CATransform3D *src, GLfloat *dst)
{
	dst[0] = src->m11;
	dst[1] = src->m12;
	dst[2] = src->m13;
	dst[3] = src->m14;
	dst[4] = src->m21;
	dst[5] = src->m22;
	dst[6] = src->m23;
	dst[7] = src->m24;
	dst[8] = src->m31;
	dst[9] = src->m32;
	dst[10] = src->m33;
	dst[11] = src->m34;
	dst[12] = src->m41;
	dst[13] = src->m42;
	dst[14] = src->m43;
	dst[15] = src->m44;
}

/* glFrustum equivalent for CATransform3D. */
CATransform3D CATransform3DMakeFrustum(CGFloat left, CGFloat right, CGFloat bottom, CGFloat top, CGFloat near, CGFloat far) {
	CATransform3D ret = CATransform3DIdentity;
	ret.m11 = 2*near/(right-left);
	ret.m22 = 2*near/(top-bottom);
	ret.m33 = (far+near)/(far-near);
	ret.m44 = 0;
	ret.m13 = (right+left)/(right-left);
	ret.m21 = (top+bottom)/(top-bottom);
	ret.m43 = -1;
	ret.m34 = 2*(far+near)/(far-near); // this element contradicts glFrustum doc, but seems to work
	return ret;
}

/* Matrix multiply and homogenize a homogeneous vector. */
CLVector CLVectorApplyCATransform3D(CATransform3D tform, const CLVector v) {
	CLVector ret;
	ret.x = tform.m11*v.x + tform.m12*v.y + tform.m13*v.z + tform.m14;
	ret.y = tform.m21*v.x + tform.m22*v.y + tform.m23*v.z + tform.m24;
	ret.z = tform.m31*v.x + tform.m32*v.y + tform.m33*v.z + tform.m34;
	double w = tform.m41*v.x + tform.m42*v.y + tform.m43*v.z + tform.m44;
	return CLVectorMultiplyScalar(ret, 1/w);
}