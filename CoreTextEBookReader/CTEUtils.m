//
//  CTEUtils.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/2/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEUtils.h"

@implementation CTEUtils

//Starts spinner on specified View
//Returns an Array of views used
//Class method
+ (NSArray *) startSpinnerOnView:(UIView *)view {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGPoint viewOrigin =[view.superview convertPoint:view.frame.origin toView:nil];
    CGFloat originOffsetY = viewOrigin.y > 0 ? viewOrigin.y : 64;//AN AWFUL HORRIBLE HACK!!! Adjusts for when status bar isn't yet realized
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    CGPoint screenCenter = CGPointMake(screenWidth / 2, (screenHeight / 2) - originOffsetY); //adjust for view location
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.center = screenCenter;
    spinner.hidesWhenStopped = YES;
    [view addSubview:spinner];
    CGRect viewRect = CGRectMake(screenCenter.x - 50, screenCenter.y - 50, 100, 100);
    UIView *rectView = [[UIView alloc] initWithFrame:viewRect];
    rectView.backgroundColor = [UIColor darkGrayColor];
    rectView.alpha = 0.8;
    rectView.layer.cornerRadius = 10;
    rectView.layer.masksToBounds = YES;
    [view insertSubview:rectView belowSubview:spinner];
    [spinner startAnimating];
    
    NSArray *views = [NSArray arrayWithObjects:spinner, rectView, nil];
    
    return views;
}

//Stops spinner on specified view using specified Array of views used
//Array returned MUST have two elements, the first the spinner, second the rect background
//Class method
+ (void) stopSpinnerOnView:(UIView *)view withSpinner:(NSArray *)spinnerObj {
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[spinnerObj objectAtIndex:0];
    UIView *rectView = (UIActivityIndicatorView *)[spinnerObj objectAtIndex:1];
    UIView *superview = spinner.superview;
    
    [spinner stopAnimating];
    [spinner removeFromSuperview];
    [rectView removeFromSuperview];
    [view setNeedsDisplay];
    [superview setNeedsDisplay];
    [view setNeedsLayout];
}

@end
