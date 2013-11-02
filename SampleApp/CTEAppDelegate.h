//
//  CTEAppDelegate.h
//  SampleApp
//
//  Created by David Jedeikin on 10/27/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTEContentViewController.h"
#import "CTEMenuViewController.h"

@interface CTEAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CTEContentViewController *contentViewController;
@property (strong, nonatomic) CTEMenuViewController *menuViewController;
@property (strong, nonatomic) NSMutableDictionary *imageCache;

- (void)showSideMenu:(NSNotification *)notification;
- (void)hideSideMenu:(NSNotification *)notification;
@end
