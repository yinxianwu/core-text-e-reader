//
//  ContentViewController.m
//  WTRMobile
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEContentViewController.h"
#import "CTEConstants.h"

@implementation CTEContentViewController

//TODO other orientations
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//side menu action
-(IBAction)slideMenuButtonTouched {
    [[NSNotificationCenter defaultCenter] postNotificationName:ShowSideMenu object:self];
}

@end
