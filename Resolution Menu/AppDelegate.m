//
//  AppDelegate.m
//  Resolution Menu
//
//  Created by Robbert Klarenbeek on 23-12-13.
//  Copyright (c) 2013 Robbert Klarenbeek. All rights reserved.
//

#import "AppDelegate.h"
#import "DisplayModeMenuItem.h"
#import <IOKit/graphics/IOGraphicsLib.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Add the menu from our NIB (self.menu) to the system status bar
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.menu];
    [self.statusItem setImage:[NSImage imageNamed:@"MenuIcon"]];
    [self.statusItem setAlternateImage:[NSImage imageNamed:@"MenuIconAlternate"]];
    [self.statusItem setHighlightMode:YES];
}

- (void)dealloc
{
    // Cleanup the system status bar menu, probably not strictly necessary at this point
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

- (IBAction)openDisplayPreferences:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Displays.prefPane"];
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    // First, clear the previous items
    for (NSMenuItem *menuItem in menu.itemArray) {
        if ([menuItem hasSubmenu] || [menuItem isKindOfClass:[DisplayModeMenuItem class]]) {
            // Remove all DisplayModeMenuItems and submenus above the first separator
            [menu removeItem:menuItem];
        } else if ([menuItem isSeparatorItem]) {
            // Break at the first separator; this way submenu's below the separator stay intact
            break;
        }
    }
    
    // Loop through all displays (max 16)
    uint32_t numberOfDisplays;
	CGDirectDisplayID displays[16];
	CGGetOnlineDisplayList(sizeof(displays) / sizeof(displays[0]), displays, &numberOfDisplays);
    for (int i = 0; i < numberOfDisplays; i++) {
        CGDirectDisplayID display = displays[i];
        
        // The menu to add the display modes to, by default directly into the main menu
        NSMenu *containerMenu = menu;
        
        // However, if we have multiple displays, put each list of display modes into its own submenu
        if (numberOfDisplays > 1) {
            NSMenu *subMenu = [NSMenu new];
            NSMenuItem *subMenuItem = [NSMenuItem new];
            
            // Use IOKit to get the (localized) device name
            NSDictionary *deviceInfo = (__bridge NSDictionary *)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(display), kIODisplayOnlyPreferredName);
            NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
            subMenuItem.title = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
            
            subMenuItem.submenu = subMenu;
            [containerMenu insertItem:subMenuItem atIndex:i];
            containerMenu = subMenu;
        }
        
        // Add the display modes to the container menu (either the main menu or a display submenu)
        NSArray *menuItems = [DisplayModeMenuItem getMenuItemsForDisplay:displays[i]];
        for (NSMenuItem *menuItem in menuItems) {
            // Add to the top of the menu, in reverse order (highest resolution first)
            [containerMenu insertItem:menuItem atIndex:0];
        }
    }
}

@end
