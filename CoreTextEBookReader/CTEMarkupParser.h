//
//  MarkupParser.h
//  CoreTextEBookReader
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
@property (strong, nonatomic) NSString *currentBodyFont;
@property (nonatomic) float currentBodyFontSize;

extern NSString * const BodyFontKey;
extern NSString * const BodyItalicFontKey;
extern NSString * const BaskervilleFontKey;
extern NSString * const GeorgiaFontKey;
extern NSString * const PalatinoFontKey;
extern NSString * const TimesNewRomanFontKey;

+(NSDictionary *)bodyFontDictionary;
+(NSDictionary *)bodyFontItalicDictionary;
-(NSAttributedString *)attrStringFromMarkup:(NSString *)html screenSize:(CGRect)size;
-(void)resetParser;

@end