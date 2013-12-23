//
//  DisplayModeMenuItem.m
//  Resolution Menu
//
//  Created by Robbert Klarenbeek on 23-12-13.
//  Copyright (c) 2013 Robbert Klarenbeek. All rights reserved.
//

#import "DisplayModeMenuItem.h"

// CoreGraphics DisplayMode struct used in private APIs
typedef struct {
    uint32_t modeNumber;
    uint32_t flags;
    uint32_t width;
    uint32_t height;
    uint32_t depth;
    uint8_t unknown[170];
    uint16_t freq;
    uint8_t more_unknown[16];
    float density;
} CGSDisplayMode;

// CoreGraphics private APIs with support for scaled (retina) display modes
void CGSGetCurrentDisplayMode(CGDirectDisplayID display, int *modeNum);
void CGSConfigureDisplayMode(CGDisplayConfigRef config, CGDirectDisplayID display, int modeNum);
void CGSGetNumberOfDisplayModes(CGDirectDisplayID display, int *nModes);
void CGSGetDisplayModeDescriptionOfLength(CGDirectDisplayID display, int idx, CGSDisplayMode *mode, int length);


@interface DisplayModeMenuItem ()

// Private properties
@property CGDirectDisplayID display;
@property CGSDisplayMode mode;

@end


@implementation DisplayModeMenuItem

- (id)initWithDisplay:(CGDirectDisplayID)display andMode:(CGSDisplayMode)mode
{
    self = [super init];
    if (self) {
        self.display = display;
        self.mode = mode;
        
        self.title = [NSString stringWithFormat: @"%d x %d", self.mode.width, self.mode.height];
        if (self.mode.density > 1.5) {
            self.title = [self.title stringByAppendingString:@" (HiDPI)"];
        }
        
        self.target = self;
        self.action = @selector(changeDisplayMode);
    }
    return self;
}

- (void)changeDisplayMode
{
    CGDisplayConfigRef config;
	CGBeginDisplayConfiguration(&config);
	CGSConfigureDisplayMode(config, self.display, self.mode.modeNumber);
	CGCompleteDisplayConfiguration(config, kCGConfigurePermanently);
}

- (NSComparisonResult)compare:(DisplayModeMenuItem *)other
{
    // Compare using width, then height, then density (HiDPI)
    
    if (self.mode.width < other.mode.width) {
        return NSOrderedAscending;
    } else if (self.mode.width > other.mode.width) {
        return NSOrderedDescending;
    } else if (self.mode.height < other.mode.height) {
        return NSOrderedAscending;
    } else if (self.mode.height > other.mode.height) {
        return NSOrderedDescending;
    } else if (self.mode.density < other.mode.density) {
        return NSOrderedAscending;
    } else if (self.mode.density > other.mode.density) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

+ (NSArray *)getMenuItemsForDisplay:(CGDirectDisplayID)display
{
    // Get the current display mode, so we can put a checkmark (NSOnState) next to it
    int currentDisplayModeNumber;
    CGSGetCurrentDisplayMode(display, &currentDisplayModeNumber);
    
    // Use a dictionary with title keys to avoid 'duplicates'
    NSMutableDictionary *menuItemsByTitle = [NSMutableDictionary new];
    
    // Loop through all display modes, but only use 1 for each unique title
    int numberOfDisplayModes;
    CGSGetNumberOfDisplayModes(display, &numberOfDisplayModes);
    for (int i = 0; i < numberOfDisplayModes; i++) {
        CGSDisplayMode mode;
        CGSGetDisplayModeDescriptionOfLength(display, i, &mode, sizeof(mode));

        DisplayModeMenuItem *menuItem = [[DisplayModeMenuItem alloc] initWithDisplay:display andMode:mode];
        DisplayModeMenuItem *previousMenuItem = menuItemsByTitle[menuItem.title];

        // Check if this display mode has a unique title or a higher color depth than a previous one
        if (previousMenuItem == nil || mode.depth > previousMenuItem.mode.depth) {
            if (mode.modeNumber == currentDisplayModeNumber || previousMenuItem.state == NSOnState) {
                // This item, or its twin (which is about to be overwritten), is active
                menuItem.state = NSOnState;
            }
            menuItemsByTitle[menuItem.title] = menuItem;
        } else if (mode.modeNumber == currentDisplayModeNumber) {
            // We won't add this mode, but it's active, so set its twin active
            [previousMenuItem setState:NSOnState];
        }
    }
    
    // Return a sorted list, from low to high resolution
    return [[menuItemsByTitle allValues] sortedArrayUsingSelector:@selector(compare:)];
}

@end
