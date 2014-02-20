//
//  CTColumnView.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEViewDelegate.h"
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <SDWebImage/SDWebImageManager.h>

@class CTEView;

@interface CTEColumnView : UIView// {
//    id ctFrame;
//}

@property (weak, nonatomic) id<CTEViewDelegate> viewDelegate;
@property (nonatomic) int textStart;
@property (nonatomic) int textEnd;
@property (strong, nonatomic) NSMutableArray *imagesWithMetadata;
@property (strong, nonatomic) NSArray *links;
@property (strong, nonatomic) NSAttributedString *attString;
@property (nonatomic) BOOL shouldDrawRect;

+(CTEColumnView *)columnWithDelegate:(id<CTEViewDelegate>)viewDelegate
                           attString:(NSAttributedString *)attString
                              images:(NSArray *)chapImages
                               links:(NSArray *)chapLinks
                                size:(CGSize)contentSize
                               frame:(CGRect)frame
                         framesetter:(CTFramesetterRef)framesetter
                             insetX:(float)frameXInset
                             insetY:(float)frameYInset
                           colOffset:(CGPoint)colOffset
                         columnWidth:(CGFloat)columnWidth
                        columnHeight:(CGFloat)columnHeight
                        textPosition:(int)textPos
                absoluteTextPosition:(int)allChapsTextPos;
//- (void)setCTFrame:(id)f;
- (void)addImage:(UIImage *)img
       imageInfo:(NSDictionary *)imageInfo
    frameXOffset:(float)frameXOffset
    frameYOffset:(float)frameYOffset;

- (void)replaceImage:(UIImage *)img imageInfo:(NSDictionary *)imageInfo;

@end
