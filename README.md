# Resolution Menu

Simple OS X status bar menu app to switch display modes / resolutions, with support for HiDPI (retina) modes.

* For quick access, if you have 1 display only, the display modes can be found at the top level of the menu. For 2 or more displays, each display will have its own submenu.

* The list of attached devices / supported display modes is refreshed each time the menu is opened; no need to ever refresh manually.

* No color depth information is shown; if a resolution is available with different color depths, only the display mode with the highest color depth will be used.

* `CoreGraphics` private APIs are used to access the HiDPI display modes; this might not get this app accepted into the Mac App Store. Also note that `CGDisplayIOServicePort()`, which is used to get the (localized) name of the displays, has been deprecated as of Mac OS X 10.9 (Mavericks).

* To facilitate "Start at Login", the `ServiceManagement.framework` is used together with a helper app, which should work in a sandboxed environment as well (as long as the app lives in /Applications).

For a command line utility with the same functionality, check out [antmd/resolution-cli](https://github.com/antmd/resolution-cli/).

## Enabling HiDPI display modes

To enable HiDPI modes on a non-retina device, execute this in the Terminal app:

```
sudo defaults write /Library/Preferences/com.apple.windowserver.plist DisplayResolutionEnabled -bool true
```

Then, for the change to take effect, either log out and back in or restart your system.

## Installation

Just fetch the latest ZIP from the [release section](https://github.com/robbertkl/ResolutionMenu/releases) section and put the extracted app into your Applications folder.

You might need to disable OS X Gatekeeper to run it: *System Preferences* > *Security & Privacy* > *General* tab > *Allow apps downloaded from: Anywhere*.

## Authors

* Robbert Klarenbeek, <robbertkl@renbeek.nl>

## Credits

* Thanks to [Alex Zielenski](https://twitter.com/#!/alexzielenski) for [StartAtLoginController](https://github.com/alexzielenski/StartAtLoginController), which ties together the ServiceManagement stuff without even a single line of code (gotta love KVO).

* Thanks to [ExitMothership](http://exitmothership.deviantart.com) for his [LED Cinema Display Icon](http://exitmothership.deviantart.com/art/LED-Cinema-Display-Icon-331815542), which is used for the app icon.

## License

Resolution Menu is published under the [MIT License](http://www.opensource.org/licenses/mit-license.php).
