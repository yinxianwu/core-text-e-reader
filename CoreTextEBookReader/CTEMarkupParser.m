//
//  MarkupParser.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEMarkupParser.h"
#import "CTEConstants.h"

//used to compute space for image
static CGFloat ascentCallback(void *ref){
    NSDictionary *imgMetadata = (__bridge NSDictionary*)ref;
    CGRect imgDimensions = [CTEMarkupParser calculateImageBounds:imgMetadata];
    return imgDimensions.size.height;
}
//used to compute space for image
//TODO this isn't used
static CGFloat descentCallback(void *ref){
    NSString *val = (NSString*)[(__bridge NSDictionary*)ref objectForKey:@"descent"];
    return [val floatValue];
}
//used to compute space for image
static CGFloat widthCallback(void* ref){
    NSDictionary *imgMetadata = (__bridge NSDictionary*)ref;
    CGRect imgDimensions = [CTEMarkupParser calculateImageBounds:imgMetadata];
    return imgDimensions.size.width;
}

@implementation CTEMarkupParser

@synthesize font;
@synthesize fontSize;
@synthesize color;
@synthesize strokeColor;
@synthesize strokeWidth;
@synthesize images;
@synthesize links;
@synthesize currentBodyFont;
@synthesize currentBodyFontSize;

//constructor; resets parser
-(id)init {
    self = [super init];
    if (self) {
        self.font = PalatinoFontKey;
        self.fontSize = 18.0f;
        self.currentBodyFont = self.font;
        self.currentBodyFontSize = self.fontSize;
        [self resetParser];
    }
    return self;
}

//used in callbacks for making space for images
+ (void)setTextContainerWidth:(CGFloat)width {
    _textContainerWidth = width;
}

//gets image sizing based on parent container
+ (CGRect)calculateImageBounds:(NSDictionary *)imgMetadata {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBounds.size.width;
    CGFloat screenHeight = screenBounds.size.height;
    NSNumber *metaWidth = (NSNumber *)[imgMetadata objectForKey:@"width"];
    NSNumber *metaHeight = (NSNumber *)[imgMetadata objectForKey:@"height"];
    CGFloat imgWidth = [metaWidth floatValue];
    CGFloat imgHeight = [metaHeight floatValue];
    
    //RULE: we ignore size tags for remote images and size per column dimensions:
    //- size proportionately up to column width up to half screen width OR
    //- size proportionately up to half of column height
    CGRect imgBounds;
    //allowable max width: column width up to half of screen width
    CGFloat allowableMaxWidth = (_textContainerWidth * 2) < screenWidth ? _textContainerWidth : screenWidth / 2;
    //allowable max height (columns are always full-height, less insets)
    CGFloat allowableMaxHeight = screenHeight * MaxImageColumnHeightRatio;
    
    //if image is smaller than both allowable max width and height, just use it as is
    if(imgWidth < allowableMaxWidth && imgHeight < allowableMaxHeight) {
        imgBounds = CGRectMake(0.0, 0.0, [metaWidth floatValue], [metaHeight floatValue]);
    }
    else {
        //try image dimensions using max width...
        CGFloat maxWidthScale = allowableMaxWidth / imgWidth;
        CGFloat scaledImgHeight = imgHeight * maxWidthScale;
        CGFloat scaledImgWidth;
        if(scaledImgHeight < allowableMaxHeight) {
            scaledImgWidth = imgWidth * maxWidthScale; //should be same as columnWidth
        }
        //..otherwise, try image dimensions using max height
        else {
            CGFloat maxHeightScale = allowableMaxHeight / imgHeight;
            scaledImgWidth = imgWidth * maxHeightScale;
            scaledImgHeight = imgHeight * maxHeightScale;
        }
        imgBounds = CGRectMake(0.0, 0.0, scaledImgWidth, scaledImgHeight);
    }
    
    return imgBounds;
}

//standard body fonts
+ (NSDictionary*)bodyFontDictionary {
    static NSDictionary *BodyFontDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BodyFontDictionary = @{BaskervilleFontKey: BaskervilleFont,
                               GeorgiaFontKey: GeorgiaFont,
                               PalatinoFontKey: PalatinoFont,
                               TimesNewRomanFontKey: TimesNewRomanFont};
    });
    return BodyFontDictionary;
}

//standard italic body fonts
+ (NSDictionary *)bodyFontItalicDictionary {
    static NSDictionary *BodyFontItalicDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BodyFontItalicDictionary = @{BaskervilleFontKey: BaskervilleFontItalic,
                                     GeorgiaFontKey: GeorgiaFontItalic,
                                     PalatinoFontKey: PalatinoFontItalic,
                                     TimesNewRomanFontKey: TimesNewRomanFont};
    });
    return BodyFontItalicDictionary;
}

//resets parser and clears image cache
- (void)resetParser {
    self.color = [UIColor blackColor];
    self.strokeColor = [UIColor whiteColor];
    self.strokeWidth = 0.0;
    self.images = [NSMutableArray array];
    self.links = [NSMutableArray array];
}

//Builds NSAttributedString from markup text
//takes into account screen size
- (NSAttributedString*)attrStringFromMarkup:(NSString *)markup screenSize:(CGRect)size {
    NSLog(@"MarkupParser: START attrStringFromMarkup");

    NSMutableAttributedString* attString = [[NSMutableAttributedString alloc] initWithString:@""];
    NSRegularExpression* regex = [[NSRegularExpression alloc]
                                  initWithPattern:@"(.*?)(<[^>]+>|\\Z)"
                                  options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                  error:nil];
    NSArray* chunks = [regex matchesInString:markup options:0
                                       range:NSMakeRange(0, [markup length])];
    for (NSTextCheckingResult* b in chunks) {
        NSArray* parts = [[markup substringWithRange:b.range]
                          componentsSeparatedByString:@"<"];
        
        CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)self.font,
                                                 self.fontSize,
                                                 NULL);
        
        //text alignment
        CTTextAlignment justifiedAlignment = kCTJustifiedTextAlignment;
        CTParagraphStyleSetting justifiedSettings[] = {
            {kCTParagraphStyleSpecifierAlignment, sizeof(justifiedAlignment), &justifiedAlignment},
        };
        CTParagraphStyleRef justifiedParagraphStyle = CTParagraphStyleCreate(justifiedSettings, sizeof(justifiedSettings) / sizeof(justifiedSettings[0]));
        
        //apply the current text style
        NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               (id)self.color.CGColor, kCTForegroundColorAttributeName,
                               (__bridge id)fontRef, kCTFontAttributeName,
                               (id)self.strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
                               (id)[NSNumber numberWithFloat: self.strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                               (__bridge id)justifiedParagraphStyle, (NSString*)kCTParagraphStyleAttributeName,
                               nil];
        
        [attString appendAttributedString:[[NSAttributedString alloc] initWithString:[parts objectAtIndex:0] attributes:attrs]];
        
        CFRelease(fontRef);
        
        //handle new formatting tag
        if ([parts count] > 1) {
            NSString* tag = (NSString*)[parts objectAtIndex:1];
            if ([tag hasPrefix:@"font"]) {
                //stroke color
                NSRegularExpression* scolorRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=strokeColor=\")\\w+"
                                                                                        options:0
                                                                                          error:NULL];
                [scolorRegex enumerateMatchesInString:tag
                                              options:0
                                                range:NSMakeRange(0, [tag length])
                                           usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                    if ([[tag substringWithRange:match.range] isEqualToString:@"none"]) {
                        self.strokeWidth = 0.0;
                    } else {
                        self.strokeWidth = -3.0;
                        SEL colorSel = NSSelectorFromString([NSString stringWithFormat: @"%@Color", [tag substringWithRange:match.range]]);
                        self.strokeColor = [UIColor performSelector:colorSel];
                    }
                }];
                
                //color
                NSRegularExpression* colorRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=color=\")\\w+"
                                                                                       options:0
                                                                                         error:NULL];
                [colorRegex enumerateMatchesInString:tag
                                             options:0
                                               range:NSMakeRange(0, [tag length])
                                          usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                    SEL colorSel = NSSelectorFromString([NSString stringWithFormat: @"%@Color", [tag substringWithRange:match.range]]);
                    self.color = [UIColor performSelector:colorSel];
                }];
                
                //size
                NSRegularExpression* sizeRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=size=\")\\w+"
                                                                                       options:0
                                                                                         error:NULL];
                [sizeRegex enumerateMatchesInString:tag
                                            options:0
                                              range:NSMakeRange(0, [tag length])
                                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                    NSString *fontSizeStr = [tag substringWithRange:match.range];
                    if([fontSizeStr isEqualToString:BodyFontSizeKey]) {
                        self.fontSize = self.currentBodyFontSize;
                    }
                    else {
                        self.fontSize = [fontSizeStr floatValue];
                    }
                }];
                
                //face -- special handling for body versus custom fonts
                NSRegularExpression* faceRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=face=\")[^\"]+"
                                                                                      options:0
                                                                                        error:NULL];
                [faceRegex enumerateMatchesInString:tag
                                            options:0
                                              range:NSMakeRange(0, [tag length])
                                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                    NSString *fontFace = [tag substringWithRange:match.range];
                    if([fontFace isEqualToString:BodyFontKey]) {
                        fontFace = (NSString *)[[CTEMarkupParser bodyFontDictionary] valueForKey:self.currentBodyFont];
                    }
                    else if([fontFace isEqualToString:BodyItalicFontKey]) {
                        fontFace = (NSString *)[[CTEMarkupParser bodyFontItalicDictionary] valueForKey:self.currentBodyFont];
                    }
                    
                    self.font = fontFace;
                }];
            } //end of font parsing
            
            //link parsing
            if ([tag hasPrefix:@"a"]) {
                NSRegularExpression* hrefRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=href=\")[^\"]+"
                                                                                      options:0
                                                                                        error:NULL];
                [hrefRegex enumerateMatchesInString:tag
                                            options:0
                                              range:NSMakeRange(0, [tag length])
                                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                                             NSString *href = [tag substringWithRange:match.range];
                                             long locationInt = [attString length];// + [href length];
                                             NSNumber *location = [NSNumber numberWithLong:locationInt];
                                             self.color = [UIColor blueColor]; //link color
                                             //add the link to the store
                                             [self.links addObject:
                                              [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               href, @"href",
                                               location, @"location",
                                               nil]
                                              ];
                }];
            }
            
            //post-link
            if ([tag hasPrefix:@"/a"]) {
                //link text is all content from opening tag to closing tag
                //link length needs to be included in link object for touch hit test
                NSString* tagBody = (NSString*)[parts objectAtIndex:0];
                NSNumber *tagBodyLength = [NSNumber numberWithLong:tagBody.length];
                NSMutableDictionary *linkData = (NSMutableDictionary *)[self.links objectAtIndex:self.links.count - 1];
                [linkData setObject:tagBodyLength forKey:@"length"];
                self.color = [UIColor blackColor]; //reset to normal color
            }
            
            //image parsing
            //use the lesser of screen width & height or specified width & height
            if ([tag hasPrefix:@"img"]) {
                //add a space to the text so that it can call the delegate
                NSDictionary *imageAttr = [self imageAttrDictionary:tag atPosition:[attString length] screenSize:size];
                [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:imageAttr]];
            }
            
            //movie parsing
            //similar to image, with extra sugar
            if ([tag hasPrefix:@"mov"]) {
                //add a space to the text so that it can call the delegate
                NSDictionary *movieAttr = [self imageAttrDictionary:tag atPosition:[attString length] screenSize:size];
                [attString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:movieAttr]];
            }
        }
    }
    
    NSLog(@"MarkupParser: END attrStringFromMarkup");
    
    return (NSAttributedString*)attString;
}

//image & movie parse
- (NSDictionary *)imageAttrDictionary:(NSString *)tag atPosition:(NSUInteger)position screenSize:(CGRect)size {
    __block NSNumber *width = [NSNumber numberWithInt:0];
    __block NSNumber *height = [NSNumber numberWithInt:0];
    __block NSString *fileName = @"";
    __block NSString *clipFileName = @"";
    
    //width
    NSRegularExpression* widthRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=width=\")[^\"]+" options:0 error:NULL];
    [widthRegex enumerateMatchesInString:tag
                                 options:0
                                   range:NSMakeRange(0, [tag length])
                              usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                                  width = [NSNumber numberWithFloat:[[tag substringWithRange: match.range] floatValue]];
                              }];
    
    //height
    NSRegularExpression* heightRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=height=\")[^\"]+" options:0 error:NULL];
    [heightRegex enumerateMatchesInString:tag
                                  options:0
                                    range:NSMakeRange(0, [tag length])
                               usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                                   height = [NSNumber numberWithFloat:[[tag substringWithRange:match.range] floatValue]];
                               }];
    
    //image URL
    NSRegularExpression *srcRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=src=\")[^\"]+" options:0 error:NULL];
    [srcRegex enumerateMatchesInString:tag
                               options:0
                                 range:NSMakeRange(0, [tag length])
                            usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                                fileName = [tag substringWithRange: match.range];
                            }];
    
    //movie URL
    NSRegularExpression *movieRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=clip=\")[^\"]+" options:0 error:NULL];
    [movieRegex enumerateMatchesInString:tag
                                 options:0
                                   range:NSMakeRange(0, [tag length])
                              usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                                  clipFileName = [tag substringWithRange: match.range];
                              }];
    
    //add the image for drawing
    //slightly different behavior for movies with preview images
    if([clipFileName length] > 0) {
        UIImage *playButtonImage = [UIImage imageNamed:@"PlayButton.png"];
        [self.images addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          width, @"width",
          height, @"height",
          fileName, @"fileName",
          clipFileName, @"clipFileName",
          playButtonImage, @"playButtonImage",
          [NSNumber numberWithLong:position], @"location",
          nil]
         ];
    }
    else {
        [self.images addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          width, @"width",
          height, @"height",
          fileName, @"fileName",
          [NSNumber numberWithLong:position], @"location",
          nil]
         ];
    }
    
    //render empty space for drawing the image in the text
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.getAscent = ascentCallback;
    callbacks.getDescent = descentCallback;
    callbacks.getWidth = widthCallback;
    
    NSDictionary* imgAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                             width, @"width",
                             height, @"height",
                             fileName, @"fileName",
                             nil];
    
    //set the delegate
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void *)(imgAttr));
    NSDictionary *attrDictionaryDelegate = [NSDictionary dictionaryWithObjectsAndKeys:
                                            (__bridge id)delegate, (NSString*)kCTRunDelegateAttributeName,
                                            nil];
    
    return attrDictionaryDelegate;
}

@end