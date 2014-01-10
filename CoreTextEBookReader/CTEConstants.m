//
//  Constants.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 10/27/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEConstants.h"

@implementation CTEConstants

//events
NSString * const ShowSideMenu = @"ShowSideMenu";
NSString * const HideSideMenu = @"HideSideMenu";
NSString * const ChangeFont = @"ChangeFont";
NSString * const ChangeFontSize = @"ChangeFontSize";
NSString * const ChangeColumnCount = @"ChangeColumnCount";
NSString * const PageForward = @"PageForward";
NSString * const PageBackward = @"PageBackward";

//settings
CGFloat const PageTurnBoundaryPhone = 50.0;
CGFloat const PageTurnBoundaryPad = 100.0;

//labels
NSString * const NavigationBarTitle = @"CoreTextEBookReader";

@end
