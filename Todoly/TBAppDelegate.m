//
//  TBAppDelegate.m
//  Todoly
//
//  Copyright (c) 2015 CloudMine, Inc. All rights reserved.
//  See LICENSE file included with project for details.
//

#import "CloudMine.h"
#import "TBAppDelegate.h"

@implementation TBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    CMAPICredentials *credentials = [CMAPICredentials sharedInstance];
    credentials.appIdentifier = @"84e5c4a381e7424b8df62e055f0b69db";
    credentials.appSecret = @"84c8c3f1223b4710b180d181cd6fb1df";
    
    return YES;
}

@end
