//
//  CTColumnView.h
//  WTRMobile
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "MediaPlayer/MediaPlayer.h"
#import "CTEImageViewController.h"
#import "CTEView.h"

@interface CTEColumnView : UIView {
    id ctFrame;
}

@property (weak, nonatomic) UIViewController *modalTarget; //TODO should really make controller this view's delegate
@property (nonatomic) int textStart;
@property (nonatomic) int textEnd;
@property (strong, nonatomic) NSMutableArray *images;
@property (strong, nonatomic) NSMutableArray *links;
@property (strong, nonatomic) NSAttributedString *attString;
@property (strong, nonatomic) MPMoviePlayerViewController *player;

-(void)setCTFrame:(id)f;
- (void)moviePlayerLoadStateChanged:(NSNotification *)notification;
- (BOOL)shouldDrawRect:(CGRect)rect;

@end
