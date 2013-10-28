//
//  CTEAppDelegate.m
//  SampleApp
//
//  Created by David Jedeikin on 10/27/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEAppDelegate.h"
#import "CTEContentViewController.h"
#import "CTEMenuViewController.h"
#import "CTEChapterViewController.h"

@implementation CTEAppDelegate


//Set appropriate top-level view ctrlrs
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // create the content view controller that contains detail content
    CTEContentViewController *contentViewCtrlr = nil;
    
    // create the menuViewController so we can swap it in as the
    // windows root view controller whenever required
    CTEMenuViewController *menuViewCtrlr = nil;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        contentViewCtrlr = [[CTEChapterViewController alloc] initWithNibName:@"ChapteriPadView" bundle:nil];
        menuViewCtrlr = [[CTEMenuViewController alloc] initWithNibName:@"MenuiPadView" bundle:nil];
    }
    else {
        contentViewCtrlr = [[CTEChapterViewController alloc] initWithNibName:@"ChapteriPhoneView" bundle:nil];
        menuViewCtrlr = [[CTEMenuViewController alloc] initWithNibName:@"MenuiPhoneView" bundle:nil];
    }
    
    self.contentViewController = contentViewCtrlr;
    self.menuViewController = menuViewCtrlr;
    
    //init image cache
    self.imageCache = [NSMutableDictionary dictionary];
    
    //set the rootViewController to the contentViewController
    self.window.rootViewController = self.contentViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
