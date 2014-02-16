//
//  CTEUtils.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/2/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTEUtils : NSObject

+ (NSArray *)startSpinnerOnView:(UIView *)view;
+ (void)stopSpinnerOnView:(UIView *)view withSpinner:(NSArray *)spinnerObj;

@end
