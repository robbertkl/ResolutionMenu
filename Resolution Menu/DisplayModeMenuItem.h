//
//  DisplayModeMenuItem.h
//  Resolution Menu
//
//  Created by Robbert Klarenbeek on 23-12-13.
//  Copyright (c) 2013 Robbert Klarenbeek. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DisplayModeMenuItem : NSMenuItem

+ (NSArray *)getMenuItemsForDisplay:(CGDirectDisplayID)display;

@end
