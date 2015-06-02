//
//  AppDelegate.m
//  code
//
//  Created by Nenad VULIC on 02/06/15.
//
//

#import "AppDelegate.h"
#import "VarSystemInfo.h"
@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    VarSystemInfo *v = [[VarSystemInfo alloc] init];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
