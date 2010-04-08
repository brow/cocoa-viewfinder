#import <OpenGLES/ES1/gl.h>
#import <QuartzCore/QuartzCore.h>
#import "CLVector.h"

/* 4x4 matrix transpose */
void transpose(GLfloat *dst, const GLfloat *src);

/* Signed angle (-180° to 180°) between 2D vectors. */
float angle2Dsigned(const float a[2], const float b[2]);

/* Convert raster coordinates to camera space coordinates between (-1, -1, focalLength) and (1, 1, focalLength) */
CLVector rasterToCamSpace(CGPoint src, CGFloat focalLength, CGSize resolution);
CGPoint camSpaceToRaster(CLVector src, CGFloat focalLength, CGSize resolution);

/* Convert CA3DTransform to OpenGL matrix. */
void matrixFromCA3DTransform(CATransform3D *src, GLfloat *dst);

/* glFrustum equivalent for CATransform3D. */
CATransform3D CATransform3DMakeFrustum(CGFloat left, CGFloat right, CGFloat bottom, CGFloat top, CGFloat near, CGFloat far);

/* Matrix multiply and homogenize a homogeneous vector. */
CLVector CLVectorApplyCATransform3D(CATransform3D tform, const CLVector v);