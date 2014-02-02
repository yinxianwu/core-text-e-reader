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
#import "CTEMarkupParser.h"

@interface CTEManager : NSObject

@property (strong, nonatomic) CTEContentViewController *contentViewController;
@property (strong, nonatomic) CTEMenuViewController *menuViewController;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CTEMarkupParser *parser;
@property (strong, nonatomic) NSArray *chapters;
@property (strong, nonatomic) UIColor *barColor;
@property (strong, nonatomic) UIColor *highlightColor;

+ (CTEManager *)managerWithWindow:(UIWindow *)window
                      andChapters:(NSArray *)chapters
                      andBarColor:(UIColor *)color
                    andHighlightColor:(UIColor *)highlight;
- (void)buildAttStrings:(NSNotification *)notification;
- (void)rebuildContentView:(NSArray *)contentData;

@end
