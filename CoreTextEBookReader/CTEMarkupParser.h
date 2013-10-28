//
//  MarkupParser.h
//  WTRMobile
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface CTEMarkupParser : NSObject

@property (strong, nonatomic) NSString *font;
@property (nonatomic) float fontSize;
@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) UIColor *strokeColor;
@property (readwrite) float strokeWidth;
@property (strong, nonatomic) NSMutableArray *images;
@property (strong, nonatomic) NSMutableArray *links;

-(NSAttributedString *)attrStringFromMarkup:(NSString *)html screenSize:(CGRect)size;
-(void)resetParser;

@end