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

@class CTEView;

@interface CTEColumnView : UIView {
    id ctFrame;
}

@property (weak, nonatomic) id<CTEViewDelegate> viewDelegate;
@property (nonatomic) int textStart;
@property (nonatomic) int textEnd;
@property (strong, nonatomic) NSMutableArray *imagesWithMetadata;
@property (strong, nonatomic) NSArray *links;
@property (strong, nonatomic) NSAttributedString *attString;
@property (nonatomic) BOOL shouldDrawRect;

- (void)setCTFrame:(id)f;
- (void)addImage:(UIImage *)img
       imageInfo:(NSDictionary *)imageInfo
    frameXOffset:(float)frameXOffset
    frameYOffset:(float)frameYOffset;

- (void)replaceImage:(UIImage *)img imageInfo:(NSDictionary *)imageInfo;

@end
