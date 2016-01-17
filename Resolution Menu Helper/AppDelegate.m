//
//  AppDelegate.m
//  Resolution Menu Helper
//
//  Created by Robbert Klarenbeek on 23-12-13.
//  Copyright (c) 2013 Robbert Klarenbeek. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath]
                            stringByDeletingLastPathComponent]
                           stringByDeletingLastPathComponent]
                          stringByDeletingLastPathComponent]
                         stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] launchApplication:appPath];
    [NSApp terminate:nil];
}

@end
