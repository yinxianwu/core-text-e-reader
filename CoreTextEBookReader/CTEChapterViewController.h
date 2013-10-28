//
//  WTRChapterViewController.h
//  WTRMobile
//
//  Created by dJedeikin on 11/20/12.
//  Copyright (c) 2012 Holocene Press. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CTEContentViewController.h"
#import "CTEView.h"
#import "CTEMarkupParser.h"

@interface CTEChapterViewController : CTEContentViewController<UIScrollViewDelegate>

//TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//@property (nonatomic, strong) Chapter *currentChapter;
//@property (nonatomic, strong) Chapter *previousChapter;

@property (nonatomic, strong) IBOutlet CTEView *ctView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIStepper *stepper;
@property (nonatomic, strong) IBOutlet UINavigationBar *navBar;
@property (nonatomic, strong) IBOutlet UILabel *currentPageLabel;
@property (nonatomic, strong) IBOutlet UILabel *pagesRemainingLabel;
@property (nonatomic, strong) CTEMarkupParser *parser;

- (IBAction)pageControlValueChanged:(id)sender;

@end
