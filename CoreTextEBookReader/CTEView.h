//
//  CTEView
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CTEColumnView;

@interface CTEView : UIScrollView {
    float frameXOffset;
    float frameYOffset;
}

extern NSString *const HTTP_PREFIX;

@property (weak, nonatomic) UIViewController *modalTarget;
@property (strong, nonatomic) NSMutableArray *columns;
@property (strong, nonatomic) NSArray *orderedKeys;
@property (strong, nonatomic) NSDictionary *attStrings;
@property (strong, nonatomic) NSDictionary *imageMetadatas;
@property (strong, nonatomic) NSDictionary *links;
@property (nonatomic) int totalPages;

- (void)setAttStrings:(NSDictionary *)allAttStrings
               images:(NSDictionary *)allImages
                links:(NSDictionary *)allLinks
                order:(NSArray *)allKeys;
- (void)buildFrames;
- (void)clearFrames;
- (void)redrawFrames;
- (int)getCurrentPage;
- (int)indexOfColumn:(id)column;

@end
