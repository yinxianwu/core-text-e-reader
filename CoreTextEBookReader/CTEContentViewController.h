//
//  ContentViewController.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEView.h"
#import "CTEChapter.h"
#import "CTEViewDelegate.h"
#import "CTEImageViewController.h"
#import "MediaPlayer/MediaPlayer.h"
#import <UIKit/UIKit.h>

@interface CTEContentViewController : UIViewController<UIScrollViewDelegate, CTEViewDelegate>

@property (nonatomic, strong) id <CTEChapter> currentChapter;
@property (nonatomic, strong) NSString *currentFont;
@property (nonatomic, strong) NSNumber *currentFontSize;
@property (nonatomic, strong) NSNumber *currentColumnsInView;
@property (nonatomic) int currentTextPosition;
@property (nonatomic, strong) NSArray *chapters;
@property (nonatomic, strong) NSMutableDictionary *attStrings;
@property (nonatomic, strong) NSDictionary *images;
@property (nonatomic, strong) NSDictionary *links;

@property (nonatomic, strong) IBOutlet CTEView *cteView;
@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) UISlider *pageSlider;
@property (nonatomic, strong) UIBarButtonItem *configButton;
@property (nonatomic, strong) UIBarButtonItem *sliderAsToolbarItem;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) MPMoviePlayerViewController *moviePlayerController;
@property (nonatomic, strong) UIColor *barColor;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
             barColor:(UIColor *)color;
- (void)rebuildContent:(NSMutableDictionary *)allAttStrings
                images:(NSDictionary *)allImages
                 links:(NSDictionary *)allLinks;
- (void)slideMenuButtonTouched:(id)sender;
//- (void)handleAppRestored:(id)sender;
- (void)playMovie:(NSString *)clipPath;
- (void)nextPage;
- (void)prevPage;
- (void)scrollToPage:(int)page animated:(BOOL)animated updateCurrentTextPosition:(BOOL)shouldUpdate;
- (int)getCurrentPage;
- (int)pageForTextPosition:(int)position;
//- (void)loa-dSettings;
- (void)saveSettings;

@end
