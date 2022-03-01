//
//  AppDelegate.m
//  TSVBMacTest
//
//  Created by Xuan Chen on 2022-02-21.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSWindow * window = [NSApplication sharedApplication].orderedWindows.firstObject;
    if (window) {
        NSSize size = NSMakeSize(1280, 720);
        [window setContentSize:size];
    }
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (IBAction)enableVBOption:(NSMenuItem *)sender {
    NSWindow * window = [NSApplication sharedApplication].orderedWindows.firstObject;
    if (window) {
        ViewController * viewController = (ViewController *)window.contentViewController;
        if (viewController) {
            [viewController changeVBOption];
            BOOL vbOption = [viewController getVBOption];
            if (!vbOption) {
                sender.title = @"Enable Virtual Background";
            } else {
                sender.title = @"Disable Virtual Background";
            }
        }
    }
}

@end
