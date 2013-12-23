//
//  AppDelegate.m
//  Resolution Menu Helper
//
//  Created by Robbert Klarenbeek on 23-12-13.
//  Copyright (c) 2013 Robbert Klarenbeek. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    // Start with the helper app's bundle path
    NSString *path = [[NSBundle mainBundle] bundlePath];
    
    // Move up 4 times (since the helper app is in <main>.app/Contents/Library/LoginItems/<helper>.app/
    for (int i = 0; i < 4; i++) {
        path = [path stringByDeletingLastPathComponent];
    }
    
    // Then get the executable path of the main app
    path = [[NSBundle bundleWithPath:path] executablePath];

    // Launch our main app
    [[NSWorkspace sharedWorkspace] launchApplication:path];
    
    // And we're done already!
    [NSApp terminate:nil];
}

@end
