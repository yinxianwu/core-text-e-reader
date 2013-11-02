//
//  MarkupParser.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEMarkupParser.h"

static CGFloat ascentCallback( void *ref ){
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"height"] floatValue];
}
static CGFloat descentCallback( void *ref ){
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"descent"] floatValue];
}
static CGFloat widthCallback( void* ref ){
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"width"] floatValue];
}

@implementation CTEMarkupParser

@synthesize font;
@synthesize fontSize;
@synthesize color;
@synthesize strokeColor;
@synthesize strokeWidth;
@synthesize images;
@synthesize links;

//constructor; resets parser
-(id)init {
    self = [super init];
    if (self) {
        [self resetParser];
    }
    return self;
}

//resets parser and clears image cache
-(void)resetParser {
    self.font = @"Arial";
    self.fontSize = 18.0;
    self.color = [UIColor blackColor];
    self.strokeColor = [UIColor whiteColor];
    self.strokeWidth = 0.0;
    self.images = [NSMutableArray array];
    self.links = [NSMutableArray array];
}

//Builds NSAttributedString from markup text
//takes into account screen size
-(NSAttributedString*)attrStringFromMarkup:(NSString *)markup screenSize:(CGRect)size {
    NSLog(@"MarkupParser: START attrStringFromMarkup");

    NSMutableAttributedString* aString = [[NSMutableAttributedString alloc] initWithString:@""];
    NSRegularExpression* regex = [[NSRegularExpression alloc]
                                  initWithPattern:@"(.*?)(<[^>]+>|\\Z)"
                                  options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators
                                  error:nil];
    NSArray* chunks = [regex matchesInString:markup options:0
                                       range:NSMakeRange(0, [markup length])];
    for (NSTextCheckingResult* b in chunks) {
        NSArray* parts = [[markup substringWithRange:b.range]
                          componentsSeparatedByString:@"<"]; //1
        
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
        
        [aString appendAttributedString:[[NSAttributedString alloc] initWithString:[parts objectAtIndex:0] attributes:attrs]];
        
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
                
                //face
                NSRegularExpression* faceRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=face=\")[^\"]+"
                                                                                      options:0
                                                                                        error:NULL];
                [faceRegex enumerateMatchesInString:tag
                                            options:0
                                              range:NSMakeRange(0, [tag length])
                                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
                    self.font = [tag substringWithRange:match.range];
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
                                             int locationInt = [aString length];// + [href length];
                                             NSNumber *location = [NSNumber numberWithInt: locationInt];
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
                NSNumber *tagBodyLength = [NSNumber numberWithInt:tagBody.length];
                NSMutableDictionary *linkData = (NSMutableDictionary *)[self.links objectAtIndex:self.links.count - 1];
                [linkData setObject:tagBodyLength forKey:@"length"];
                self.color = [UIColor blackColor]; //reset to normal color
            }
            
            //image parsing
            //use the lesser of screen width & height or specified width & height
            if ([tag hasPrefix:@"img"]) {
                //add a space to the text so that it can call the delegate
                NSDictionary *imageAttr = [self imageAttrDictionary:tag atPosition:[aString length] screenSize:size];
                [aString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:imageAttr]];
            }
            
            //movie parsing
            //similar to image, with extra sugar
            if ([tag hasPrefix:@"mov"]) {
                //add a space to the text so that it can call the delegate
                NSDictionary *movieAttr = [self imageAttrDictionary:tag atPosition:[aString length] screenSize:size];
                [aString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:movieAttr]];
            }
        }
    }
    
    NSLog(@"MarkupParser: END attrStringFromMarkup");
    
    return (NSAttributedString*)aString;
}

//image & movie parse
- (NSDictionary *)imageAttrDictionary:(NSString *)tag atPosition:(NSUInteger)position screenSize:(CGRect)size {
    __block NSNumber *width = [NSNumber numberWithInt:0];
    __block NSNumber *height = [NSNumber numberWithInt:0];
    __block NSString *fileName = @"";
    __block NSString *clipFileName = @"";
    __block NSNumber *scaling = [NSNumber numberWithFloat:1.0]; //if width needs to be adjusted to fit in the column, so does height
    
    //width
    NSRegularExpression* widthRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=width=\")[^\"]+" options:0 error:NULL];
    [widthRegex enumerateMatchesInString:tag
                                 options:0
                                   range:NSMakeRange(0, [tag length])
                              usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                                  CGFloat screenWidth = size.size.width - 60; //account for insetting TODO might need better computation
                                  CGFloat imageWidth = [[tag substringWithRange: match.range] floatValue];
                                  width = imageWidth > screenWidth ?
                                  [NSNumber numberWithFloat:screenWidth] :
                                  [NSNumber numberWithFloat:imageWidth];
                                  scaling = [NSNumber numberWithFloat:[width floatValue] / imageWidth];
                              }];
    
    //height
    NSRegularExpression* heightRegex = [[NSRegularExpression alloc] initWithPattern:@"(?<=height=\")[^\"]+" options:0 error:NULL];
    [heightRegex enumerateMatchesInString:tag
                                  options:0
                                    range:NSMakeRange(0, [tag length])
                               usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                                   NSNumber *unscaledHeight = [NSNumber numberWithInt: [[tag substringWithRange:match.range] intValue]];
                                   height = [NSNumber numberWithFloat:[unscaledHeight floatValue] * [scaling floatValue]];
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
          [NSNumber numberWithInt:position], @"location",
          nil]
         ];
    }
    else {
        [self.images addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          width, @"width",
          height, @"height",
          fileName, @"fileName",
          [NSNumber numberWithInt:position], @"location",
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
                             nil];
    
    //set the delegate
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks, (__bridge void *)(imgAttr));
    NSDictionary *attrDictionaryDelegate = [NSDictionary dictionaryWithObjectsAndKeys:
                                            (__bridge id)delegate, (NSString*)kCTRunDelegateAttributeName,
                                            nil];
    
    return attrDictionaryDelegate;
}

@end