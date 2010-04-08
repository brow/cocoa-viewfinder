//
//  CocoaViewfinderAppDelegate.m
//  CocoaViewfinder
//
//  Created by Tom Brow on 4/7/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "CocoaViewfinderAppDelegate.h"

@implementation CocoaViewfinderAppDelegate

@synthesize window;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	viewController = [[UIViewController alloc] init];
	
	[window addSubview:[viewController view]];
	[window makeKeyAndVisible];	
}

- (void)dealloc {
	[viewController release];
    [window release];
    [super dealloc];
}

@end
