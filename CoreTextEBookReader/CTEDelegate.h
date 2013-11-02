//
//  CTEDelegate.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/2/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTEContentViewController.h"
#import "CTEMenuViewController.h"

@interface CTEDelegate : NSObject

@property (strong, nonatomic) CTEContentViewController *contentViewController;
@property (strong, nonatomic) CTEMenuViewController *menuViewController;
@property (strong, nonatomic) UIWindow *window;

+ (CTEDelegate *)delegateWithWindow:(UIWindow *)window andChapters:(NSArray *)chapters;

@end
