//
//  ContentViewController.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTEView.h"
#import "CTEMarkupParser.h"
#import "CTEChapter.h"

@interface CTEContentViewController : UIViewController<UIScrollViewDelegate>

@property (nonatomic) NSInteger contentIndex;


@property (nonatomic, strong) id <CTEChapter> currentChapter;
@property (nonatomic, strong) id <CTEChapter> previousChapter;

@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) IBOutlet CTEView *ctView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIStepper *stepper;
@property (nonatomic, strong) IBOutlet UILabel *currentPageLabel;
@property (nonatomic, strong) IBOutlet UILabel *pagesRemainingLabel;
@property (nonatomic, strong) CTEMarkupParser *parser;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil chapter:(id<CTEChapter>)chapter;
- (IBAction)pageControlValueChanged:(id)sender;
- (void)slideMenuButtonTouched:(id)sender;

@end
