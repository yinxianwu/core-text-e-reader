//
//  CTView.h
//  WTRMobile
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTEColumnView.h"

@interface CTEView : UIScrollView {
    float frameXOffset;
    float frameYOffset;
}

@property (weak, nonatomic) UIViewController *modalTarget;
@property (strong, nonatomic) NSAttributedString *attString;
@property (strong, nonatomic) NSMutableArray *columns;
@property (strong, nonatomic) NSMutableArray *columnsRendered;
@property (strong, nonatomic) NSMutableArray *imageMetadatas;
@property (strong, nonatomic) NSMutableArray *links;
@property (nonatomic) int totalPages;

- (void)setAttString:(NSAttributedString *)attString withImages:(NSArray *)imgs andLinks:(NSArray *)lnks;
- (void)buildFrames;
- (void)clearFrames;
- (void)redrawFrames;
- (int)getCurrentPage;
- (int)indexOfColumn:(id)column;

@end
