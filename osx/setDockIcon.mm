#import <AppKit/AppKit.h>

// SDL's Cocoa backend creates NSApplication and calls finishLaunching manually,
// which does not trigger the automatic bundle icon loading that occurs when
// the OS launches the app. Set it explicitly from the bundle resource so the
// dock shows the correct icon instead of a generic one.
void setMacOSDockIcon()
{
    NSImage* icon = [[NSBundle mainBundle] imageForResource:@"EmptyEpsilon"];
    if (icon)
        [NSApp setApplicationIconImage:icon];
}
