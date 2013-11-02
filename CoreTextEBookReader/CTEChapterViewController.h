//
//  WTRChapterViewController.h
//  CoreTextEBookReader
//
//  Created by dJedeikin on 11/20/12.
//  Copyright (c) 2012 Holocene Press. All rights reserved.
//

#import "CTEContentViewController.h"
#import "CTEView.h"
#import "CTEMarkupParser.h"
#import "CTEChapter.h"

@interface CTEChapterViewController : CTEContentViewController<UIScrollViewDelegate>

@property (nonatomic, strong) id <CTEChapter> currentChapter;
@property (nonatomic, strong) id <CTEChapter> previousChapter;

@property (nonatomic, strong) IBOutlet CTEView *ctView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIStepper *stepper;
@property (nonatomic, strong) IBOutlet UINavigationBar *navBar;
@property (nonatomic, strong) IBOutlet UILabel *currentPageLabel;
@property (nonatomic, strong) IBOutlet UILabel *pagesRemainingLabel;
@property (nonatomic, strong) CTEMarkupParser *parser;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil chapter:(id<CTEChapter>)chapter;
- (IBAction)pageControlValueChanged:(id)sender;
//- (void)handleChapterSelected:(NSNotification *)notification;

@end
