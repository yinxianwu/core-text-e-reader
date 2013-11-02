//
//  WTRChapterViewController.m
//  CoreTextEBookReader
//
//  Created by dJedeikin on 11/20/12.
//  Copyright (c) 2012 Holocene Press. All rights reserved.

#import "CTEChapterViewController.h"
#import "CTEImageViewController.h"
#import "CTEChapter.h"
#import "CTEConstants.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface CTEChapterViewController ()
@property (nonatomic, strong) NSArray *spinnerViews;
@end

@implementation CTEChapterViewController

@synthesize currentChapter = _currentChapter;
@synthesize previousChapter = _previousChapter;

@synthesize ctView;
@synthesize pageControl;
@synthesize stepper;
@synthesize parser;
@synthesize spinnerViews;
@synthesize currentPageLabel;
@synthesize pagesRemainingLabel;
@synthesize navBar;

//Constructor
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil chapter:(id<CTEChapter>)chapter {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    _currentChapter = chapter;
    self.parser = [[CTEMarkupParser alloc] init];

    return self;
}

//inits the UI elements
- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(handleChapterSelected:)
//                                                 name:HideSideMenu
//                                               object:nil];
    
    //height adjustment for first time view is shown
    //this is an issue when displaying on 3.5-inch displays
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGRect viewRect = [self.view bounds];
        
        if(viewRect.size.height > screenRect.size.height) {
            CGRect ctViewRect = [ctView bounds];
            CGRect ctViewNewRect = CGRectMake(ctViewRect.origin.x, ctViewRect.origin.y, ctViewRect.size.width, screenRect.size.height - 88);
            [ctView setFrame:ctViewNewRect];
        }
    }
}

//Load data into view
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //don't reload if it's the same chapter
    if(self.previousChapter == self.currentChapter) {
        return;
    }

    //nav bar title
    UINavigationItem *navItem = [[navBar items] objectAtIndex:0];
    [navItem setTitle:_currentChapter.title];

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    [ctView clearFrames];
    [parser resetParser];

    //parse to derive attributed string
    NSAttributedString *attString = [parser attrStringFromMarkup:self.currentChapter.body screenSize:screenRect];
    self.ctView.modalTarget = self; //TODO this should be redone as delegate pattern
    [self.ctView setAttString:attString withImages:parser.images andLinks:parser.links];
    [self.ctView buildFrames];
    
    //different impls for paging
    if(self.pageControl) {
        self.pageControl.numberOfPages = [ctView totalPages];
        self.pageControl.currentPage = 0;
    }
    else if(self.stepper) {
        self.stepper.maximumValue = [ctView totalPages];
        self.stepper.minimumValue = 0.0;
        self.stepper.value = 0.0;
    }
    
    //init page labels
    NSString *pagesRemaining = [NSString stringWithFormat:@"%d", [ctView totalPages]];
    [currentPageLabel setText:@"1"];
    [pagesRemainingLabel setText:pagesRemaining];
}

//Set specified chapter as current
//- (void)handleChapterSelected:(NSNotification *)notification {
//    id<CTEChapter> chapter = (id<CTEChapter>)[notification object];
//    [self setCurrentChapter:chapter];
//}

//if an image view, caches the current index to prevent reloads
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^)(void))completion NS_AVAILABLE_IOS(5_0) {
    if([viewControllerToPresent isKindOfClass:[CTEImageViewController class]]) {
        [self setContentIndex:self.contentIndex];
    }
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}


//Respond to scroll events from the CTView
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // Update the page when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.ctView.frame.size.width;
    int page = floor((self.ctView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;

    //different impls for paging
    if(self.pageControl) {
        self.pageControl.currentPage = page;
    }
    else if(self.stepper) {
        self.stepper.value = page;
    }
    
    //update page labels
    double currentPage = 0.0;
    if(self.pageControl) {
        currentPage = self.pageControl.currentPage;
    }
    else if(self.stepper) {
        currentPage = self.stepper.value;
    }
    int currentPageInt = currentPage + 1;
    int pagesRemainingInt = [ctView totalPages] - currentPage;
    NSString *pagesRemainingStr = [NSString stringWithFormat:@"%d", pagesRemainingInt];
    NSString *currentPageStr = [NSString stringWithFormat:@"%d", currentPageInt];
    [currentPageLabel setText:currentPageStr];
    [pagesRemainingLabel setText:pagesRemainingStr];
}

//Respond to page control changes
- (IBAction)pageControlValueChanged:(id)sender {
    CGRect frame;
    // update the scroll view to the appropriate page
    double currentPage = 0.0;
    if(sender == self.pageControl) {
        currentPage = self.pageControl.currentPage;
    }
    else if(sender == self.stepper) {
        currentPage = self.stepper.value;
    }
    frame.origin.x = self.ctView.frame.size.width * currentPage;
    frame.origin.y = 0;
    frame.size = self.ctView.frame.size;
    [self.ctView scrollRectToVisible:frame animated:YES];
}

//performs column redraw
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [ctView redrawFrames];
}

//performs column redraw
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [ctView redrawFrames];
}

//detect touches on page labels
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    UIView * view = touch.view;
    int pageDirection = 0;
    
    if(view == self.currentPageLabel) {
        pageDirection--;
    }
    else if(view == self.pagesRemainingLabel) {
        pageDirection++;
    }
    //don't do anything if a page control wasn't touched
    else {
        return;
    }
    
    CGRect frame;
    // update the page controls to the appropriate page
    double currentPage = 0.0;
    if(self.pageControl) {
        self.pageControl.currentPage = self.pageControl.currentPage + pageDirection;
        currentPage = self.pageControl.currentPage;
    }
    else if(self.stepper) {
        self.pageControl.currentPage = self.stepper.value + pageDirection;
        currentPage = self.stepper.value;
    }
    frame.origin.x = self.ctView.frame.size.width * currentPage;
    frame.origin.y = 0;
    frame.size = self.ctView.frame.size;
    [self.ctView scrollRectToVisible:frame animated:YES];

}

//sets current chapter and caches previous
- (void)setCurrentChapter:(id<CTEChapter>) chapter {
    _previousChapter = _currentChapter;
    _currentChapter = chapter;
}

@end
