//
//  CTEView
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEChapter.h"
#import "CTEViewDelegate.h"
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@class CTEColumnView;

@interface CTEView : UIScrollView {
    float frameXOffset;
    float frameYOffset;
}

extern NSString *const HTTP_PREFIX;

@property (weak, nonatomic) id<CTEViewDelegate> viewDelegate;
@property (strong, nonatomic) NSMutableArray *columns;
@property (strong, nonatomic) NSArray *orderedKeys;
@property (strong, nonatomic) NSDictionary *attStrings;
@property (strong, nonatomic) NSDictionary *imageMetadatas;
@property (strong, nonatomic) NSDictionary *links;
@property (strong, nonatomic) NSMutableArray *orderedChapterPages;
@property (nonatomic, strong) NSNumber *currentChapterID;
@property (nonatomic) int totalPages;
@property (nonatomic) int pageColumnCount;

- (void)setAttStrings:(NSDictionary *)allAttStrings
               images:(NSDictionary *)allImages
                links:(NSDictionary *)allLinks
                order:(NSArray *)allKeys;
- (void)buildFrames;
- (int)getCurrentPage;
- (int)indexOfColumn:(id)column;
- (void)currentChapterNeedsUpdate;
- (NSNumber *)pageNumberForChapterID:(NSNumber *)chapterID;
- (void)addImage:(UIImage *)img forColumn:(CTEColumnView *)col frameRef:(CTFrameRef)frameRef imageInfo:(NSDictionary *)imageInfo;
- (void)replaceImage:(UIImage *)img forColumn:(CTEColumnView *)col imageInfo:(NSDictionary *)imageInfo;
@end
