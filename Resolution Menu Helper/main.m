//
//  main.m
//  Resolution Menu Helper
//
//  Created by Robbert Klarenbeek on 23-12-13.
//  Copyright (c) 2013 Robbert Klarenbeek. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[])
{
    AppDelegate *delegate = [[AppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
}
