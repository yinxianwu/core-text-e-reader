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

@property (nonatomic) NSInteger contentIndex;

@property (nonatomic, strong) id <CTEChapter> currentChapter;

@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) IBOutlet CTEView *cteView;

@property (nonatomic, strong) NSArray *chapters;
@property (nonatomic, strong) NSDictionary *attStrings;
@property (nonatomic, strong) NSDictionary *images;
@property (nonatomic, strong) NSDictionary *links;
@property (strong, nonatomic) MPMoviePlayerViewController *player;
//@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
//@property (nonatomic, strong) IBOutlet UIStepper *stepper;
//@property (nonatomic, strong) IBOutlet UILabel *currentPageLabel;
//@property (nonatomic, strong) IBOutlet UILabel *pagesRemainingLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
             chapters:(NSArray *)allChapters
           attStrings:(NSDictionary *)allAttStrings
               images:(NSDictionary *)allImages
                links:(NSDictionary *)allLinks;
- (IBAction)pageControlValueChanged:(id)sender;
- (void)slideMenuButtonTouched:(id)sender;
- (void)playMovie:(NSString *)clipPath;

@end
