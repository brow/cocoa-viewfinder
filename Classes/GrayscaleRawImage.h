//
//  GrayscaleRawImage.h
//  CameraTest
//
//  Created by Tom Brow on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RawImage.h"


@interface GrayscaleRawImage : RawImage {

}

- (GrayscaleRawImage *) smoothedImageInBuffer:(void *)buffer;

@end
