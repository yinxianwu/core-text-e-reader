//
//  CTEAppDelegate.h
//  SampleApp
//
//  Created by David Jedeikin on 10/27/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEDelegate.h"
#import "CTEContentViewController.h"
#import "CTEMenuViewController.h"
#import <UIKit/UIKit.h>

@interface CTEAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CTEDelegate *delegate;
//@property (strong, nonatomic) CTEContentViewController *contentViewController;
//@property (strong, nonatomic) CTEMenuViewController *menuViewController;

//- (void)showSideMenu:(NSNotification *)notification;
//- (void)hideSideMenu:(NSNotification *)notification;
@end
