//
//  main.m
//  resolution-cli
//
//  Created by Anthony Dervish on 01/02/2014.
//  Copyright (c) 2014 Robbert Klarenbeek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#include <string>
#include <iostream>
#include <vector>
#include <utility>
#include <memory>
#include <iomanip>
#include <set>
#include <regex>
#include <algorithm>
#include <libgen.h> // For basename
using namespace std;


struct DisplayMode
{
    uint32_t modeNumber;
    int32_t width;
    int32_t height;
    int32_t depth;
    int hidpi;
    bool active;
    
    DisplayMode(uint32_t modeNumber=0, int32_t width=-1, int32_t height=-1, int32_t depth=-1, int hidpi=false, bool active=false):
    modeNumber(modeNumber)
    ,width(width)
    ,height(height)
    ,depth(depth)
    ,hidpi(hidpi)
    ,active(active)
    {;}
    
    bool operator<(const DisplayMode& rhs) const {
        if (width < rhs.width) { return true; }
        else if (width == rhs.width) {
            if (height < rhs.height) { return true; }
            else if ( height == rhs.height) {
                if (depth < rhs.depth) { return true; }
                else if (depth == rhs.depth) {
                    return !hidpi && rhs.hidpi;
                }
            }
        }
        return false;
    }
    
    bool matches(const DisplayMode& rhs) const {
        if ((rhs.width>=0 && width != rhs.width) ||
            (rhs.height >=0 && height != rhs.height) ||
            (rhs.depth >=0 && depth != rhs.depth) ||
            (rhs.hidpi >=0 && hidpi != rhs.hidpi)) {
            return false;
        }
        return true;
    }
    
    friend ostream& operator<<(ostream& os,const DisplayMode& resolution) {
        os << (resolution.active ? ">>> " : "    ");
        os << setw(4) << resolution.width << " x " << setw(4) << resolution.height
        << " @ " << (resolution.depth>=0?(2<<resolution.depth):-1) << " bits";
        if (resolution.hidpi) {
            os << " HiDPI";
        }
        return os;
    };
};

using DisplayModes = set<DisplayMode>;
using DisplayID = CGDirectDisplayID;

struct DisplayInfo
{
    DisplayID displayID;
    string name;
    DisplayModes displayModes;
    DisplayInfo(DisplayID displayID, string name, DisplayModes displayModes) :
    displayID(displayID), name(move(name)), displayModes(move(displayModes)) {;}
};

using DisplayToDisplayInfo = vector<DisplayInfo>;


/*
 *
 *
 *================================================================================================*/
#pragma mark - Private CoreGraphics API
/*==================================================================================================
 */

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

extern "C" {
// CoreGraphics private APIs with support for scaled (retina) display modes
void CGSGetCurrentDisplayMode(CGDirectDisplayID display, int *modeNum);
void CGSConfigureDisplayMode(CGDisplayConfigRef config, CGDirectDisplayID display, int modeNum);
void CGSGetNumberOfDisplayModes(CGDirectDisplayID display, int *nModes);
void CGSGetDisplayModeDescriptionOfLength(CGDirectDisplayID display, int idx, CGSDisplayMode *mode, int length);
}


/*
 *
 *
 *================================================================================================*/
#pragma mark - Functions
/*==================================================================================================
 */


void usage(const char* binary) {
    string binaryName(basename((char*)binary));
    cout << binaryName << ": " << "Change the screen resolution on OS X" << endl << endl
    << " Usage: " << binaryName << " <command> [<argument> <argument>]" << endl
    << R"(
    Commands:
        list - list the available resolutions
        set <display-index> <resolution> - set the resolution
    
    <resolution> can be specified in several ways, and an underscore can be used
    anywhere a number might be used meaning 'match anything' in a search from highest-
    resolution to lowest resolution.
    
    Examples for <resolution>:
        1920x1080@32h = display mode size 1920x1080, 32 bit colour, HiDPI
        2560      = first mode with 2560 width
        1920x1080 = first mode with size 1920x1080
        _x900     = first mode with height 900
        _x_@16    = first mode with 16-bit colour
        h         = first HiDPI mode
        _         = Highest resolution mode -- often the default
    )" << endl;
}

DisplayToDisplayInfo getDisplayModes() {
    // One-shot mode -- we do not have to take account of changed display info
    static unique_ptr<DisplayToDisplayInfo> sDisplayInfo;
    
    if (!sDisplayInfo) {
        sDisplayInfo.reset(new DisplayToDisplayInfo());
        uint32_t numberOfDisplays;
        CGDirectDisplayID displays[16];
        CGGetOnlineDisplayList(sizeof(displays) / sizeof(displays[0]), displays, &numberOfDisplays);
        for (int i = 0; i < numberOfDisplays; i++) {
            CGDirectDisplayID display = displays[i];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            NSDictionary *deviceInfo = (__bridge NSDictionary *)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(display), kIODisplayOnlyPreferredName);
#pragma clang diagnostic pop
            NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
            NSString* displayName = localizedNames[[localizedNames allKeys][0]];
            
            // Get the current display mode, so we can put a checkmark (NSOnState) next to it
            int currentDisplayModeNumber;
            CGSGetCurrentDisplayMode(display, &currentDisplayModeNumber);
            
            // Loop through all display modes, but only use 1 for each unique title
            int numberOfDisplayModes;
            CGSGetNumberOfDisplayModes(display, &numberOfDisplayModes);
            DisplayModes displayModes;
            
            for (int i = 0; i < numberOfDisplayModes; i++) {
                CGSDisplayMode mode;
                CGSGetDisplayModeDescriptionOfLength(display, i, &mode, sizeof(mode));
                
                displayModes.emplace(
                    mode.modeNumber,
                    mode.width,
                    mode.height,
                    mode.depth,
                    (mode.density>1.5),
                    (mode.modeNumber == currentDisplayModeNumber)
                );
                
            }
            sDisplayInfo->emplace_back(display, string(displayName.UTF8String), displayModes);
        }
    }
    return *sDisplayInfo;
}
void listDisplayModes() {
    DisplayToDisplayInfo displayInfo(getDisplayModes());
    for (size_t idx = 0; idx < displayInfo.size(); ++idx ) {
        cout << idx << ": " << displayInfo[idx].name << endl;
        for ( const DisplayMode& info : displayInfo[idx].displayModes ) {
            cout << info << endl;
        }
        cout << endl;
    }
    
}


void changeDisplayMode(CGDirectDisplayID display, int modeNumber)
{
    CGDisplayConfigRef config;
	CGBeginDisplayConfiguration(&config);
	CGSConfigureDisplayMode(config, display, modeNumber);
	CGCompleteDisplayConfiguration(config, kCGConfigurePermanently);
}

DisplayMode displayModeFromString(const string& displayStr) {
    
    DisplayMode displayMode;
    regex sizeRe(R"((_|[0-9]+)x(_|[0-9]+))");
    smatch sizeMatch;
    try {
        string restOfString(displayStr);
        if (regex_search(displayStr, sizeMatch, sizeRe)) {
            displayMode.width = sizeMatch[1]=="_" ? -1 : stoi(sizeMatch[1]);
            displayMode.height = sizeMatch[2]=="_" ? -1 : stoi(sizeMatch[2]);
            
            restOfString = sizeMatch.suffix().str();
            
            regex depthRe(R"(@(_|[0-9]+))");
            smatch depthMatch;
            if (regex_search(restOfString,depthMatch,depthRe)) {
                displayMode.depth = log2(stoi(depthMatch[1]))-1;
                restOfString = depthMatch.suffix().str();
            }
        }
        
        regex hidpiRe(R"(^ *h(i(d(p(i)?)?)?)?)",regex_constants::icase);
        if (regex_match(restOfString, hidpiRe)) {
            displayMode.hidpi=true;
        }
        
    }
    catch( const exception& e) {
        cerr << "Exception converting display mode : " << e.what() << endl;
    }
    return displayMode;
}


int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        DisplayToDisplayInfo displayModes(getDisplayModes());
        
        if (argc < 2) {
            usage(argv[0]);
            exit(0);
        }
        
        if (string("set") == argv[1]) {
            if (argc<4) {
                cerr << "Must supply a display and resolution to 'set' command" << endl;
                usage(argv[0]);
                exit(1);
            }
            size_t selectedDisplayIdx(stod(argv[2]));
            DisplayMode selectedMode(displayModeFromString(argv[3]));
            
            DisplayInfo infoForSelectedDisplay(displayModes[selectedDisplayIdx]);
            DisplayID selectedDisplayID(infoForSelectedDisplay.displayID);
            DisplayModes modesForSelectedDisplay(infoForSelectedDisplay.displayModes);
            auto modeItr = find_if(modesForSelectedDisplay.rbegin()
                    ,modesForSelectedDisplay.rend()
                    ,[&selectedMode](const DisplayMode&displayMode){return displayMode.matches(selectedMode);});
            if (modeItr != modesForSelectedDisplay.rend()) {
                cout << "Switching display '" << infoForSelectedDisplay.name << "' (" << selectedDisplayIdx << ") to mode " << *modeItr << endl;
                changeDisplayMode(selectedDisplayID, (int)modeItr->modeNumber);
            }
            else {
                cerr << "Could not find a match for " << selectedMode << endl;
            }
            
        }
        else if (string("list") == argv[1]) {
            listDisplayModes();
        }
        else {
            cerr << "Unknown command '" << argv[1] << "'" << endl;
            usage(argv[0]);
            exit(1);
        }
        
    } // autoreleasepool
    return 0;
}

