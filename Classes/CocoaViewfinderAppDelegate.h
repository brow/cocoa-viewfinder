//
//  CocoaViewfinderAppDelegate.h
//  CocoaViewfinder
//
//  Created by Tom Brow on 4/7/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CocoaViewfinderAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UIViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

