//
//  CTEViewDelegate.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/7/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CTEViewDelegate <NSObject>

- (void)playMovie:(NSString *)clipPath;
- (void)showImage:(UIImage *)image;

@end
