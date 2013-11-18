//
//  ContentViewController.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEContentViewController.h"
#import "CTEConstants.h"
#import "CTEImageViewController.h"
#import "CTEChapter.h"
#import "CTEConstants.h"
#import "CTEUtils.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface CTEContentViewController ()
@property (nonatomic, strong) NSArray *spinnerViews;
@property (nonatomic) float decelOffsetX;
@end

@implementation CTEContentViewController

@synthesize cteView;
//@synthesize pageControl;
//@synthesize stepper;
//@synthesize currentPageLabel;
//@synthesize pagesRemainingLabel;
@synthesize spinnerViews;
@synthesize decelOffsetX;
@synthesize navBar;
@synthesize player;

@synthesize currentChapter;
@synthesize chapters;
@synthesize attStrings;
@synthesize images;
@synthesize links;

//Constructor
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
             chapters:(NSArray *)allChapters
           attStrings:(NSDictionary *)allAttStrings
               images:(NSDictionary *)allImages
                links:(NSDictionary *)allLinks {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self.chapters = allChapters;
    self.attStrings = allAttStrings;
    self.images = allImages;
    self.links = allLinks;
    self.decelOffsetX = 0.0f;
    
    return self;
}

//inits the UI elements
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *orderedSet = [NSMutableArray arrayWithCapacity:[self.chapters count]];
    for(id<CTEChapter> chapter in self.chapters) {
        [orderedSet addObject:[chapter id]];
    }

    self.cteView.viewDelegate = self;
    [self.cteView setAttStrings:self.attStrings
                         images:self.images
                          links:self.links
                          order:orderedSet];
    [self.cteView buildFrames];

    BOOL isIOS7 = (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1);
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat navBarHeight = 64.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        //height adjustment for first time view is shown
        //this is an issue when displaying on 3.5-inch displays
        CGRect viewRect = [self.view bounds];
        if(viewRect.size.height > screenRect.size.height) {
            CGRect ctViewRect = [cteView bounds];
            CGRect ctViewNewRect = CGRectMake(ctViewRect.origin.x, ctViewRect.origin.y, ctViewRect.size.width, screenRect.size.height - 88);
            [cteView setFrame:ctViewNewRect];
        }
    }
    
    CGFloat red = 225.0f/255.0f;
    CGFloat green = 210.0f/255.0f;
    CGFloat blue = 169.0f/255.0f;
    UIColor *navBarDefaultColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
    UIColor *navBarColor = nil;
    if(isIOS7) {
        [[UINavigationBar appearance] setBarTintColor:navBarDefaultColor];
        navBarColor = [UIColor blackColor];
    }
    else {
        navBarColor = navBarDefaultColor;
        navBarHeight -= 20.0f;
    }
    
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor blackColor],UITextAttributeTextColor,
//                                               [UIColor blackColor], UITextAttributeTextShadowColor,
//                                               [NSValue valueWithUIOffset:UIOffsetMake(-1, 0)], UITextAttributeTextShadowOffset,
                                               nil];
    
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, navBarHeight)];
    if(!isIOS7) [navBar setBarStyle:UIBarStyleBlack];
    [navBar setDelegate:self];
    [navBar setTintColor:navBarColor];
    [self.view addSubview:navBar];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                  initWithImage:[UIImage imageNamed:@"ThreeLines.png"]
                                  style:UIBarButtonItemStyleBordered
                                  target:self
                                  action:@selector(slideMenuButtonTouched:)];
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"WTR Mobile"];
    item.leftBarButtonItem = addButton;
    [navBar pushNavigationItem:item animated:false];
}

//side menu action
-(void)slideMenuButtonTouched:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ShowSideMenu object:self];
}

//if an image view, caches the current index to prevent reloads
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^)(void))completion NS_AVAILABLE_IOS(5_0) {
    if([viewControllerToPresent isKindOfClass:[CTEImageViewController class]]) {
        [self setContentIndex:self.contentIndex];
    }
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

//TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//Respond to scroll events from the CTView
- (void)scrollViewDidScroll:(UIScrollView *)sender {
//    // Update the page when more than 50% of the previous/next page is visible
//    CGFloat pageWidth = self.ctView.frame.size.width;
//    int page = floor((self.decelOffsetX - pageWidth / 2) / pageWidth) + 1;
//    
//    //different impls for paging
//    if(self.pageControl) {
//        self.pageControl.currentPage = page;
//    }
//    else if(self.stepper) {
//        self.stepper.value = page;
//    }
//    
//    //update page labels
//    double currentPage = 0.0;
//    if(self.pageControl) {
//        currentPage = self.pageControl.currentPage;
//    }
//    else if(self.stepper) {
//        currentPage = self.stepper.value;
//    }
//    int currentPageInt = currentPage + 1;
//    int pagesRemainingInt = [ctView totalPages] - currentPage;
//    NSString *pagesRemainingStr = [NSString stringWithFormat:@"%d", pagesRemainingInt];
//    NSString *currentPageStr = [NSString stringWithFormat:@"%d", currentPageInt];
//    [currentPageLabel setText:currentPageStr];
//    [pagesRemainingLabel setText:pagesRemainingStr];
}

//TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//Respond to page control changes
- (IBAction)pageControlValueChanged:(id)sender {
//    CGRect frame;
//    // update the scroll view to the appropriate page
//    double currentPage = 0.0;
//    if(sender == self.pageControl) {
//        currentPage = self.pageControl.currentPage;
//    }
//    else if(sender == self.stepper) {
//        currentPage = self.stepper.value;
//    }
//    frame.origin.x = self.ctView.frame.size.width * currentPage;
//    frame.origin.y = 0;
//    frame.size = self.ctView.frame.size;
//    [self.ctView scrollRectToVisible:frame animated:YES];
}

//TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    self.decelOffsetX = self.cteView.contentOffset.x;
}

//performs column redraw
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [cteView currentChapterNeedsUpdate];
}

//TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//performs column redraw
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
}

//TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//detect touches on page labels
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
//    [super touchesBegan:touches withEvent:event];
//    UITouch *touch = [touches anyObject];
//    UIView * view = touch.view;
//    int pageDirection = 0;
//    
//    if(view == self.currentPageLabel) {
//        pageDirection--;
//    }
//    else if(view == self.pagesRemainingLabel) {
//        pageDirection++;
//    }
//    //don't do anything if a page control wasn't touched
//    else {
//        return;
//    }
//    
//    CGRect frame;
//    // update the page controls to the appropriate page
//    double currentPage = 0.0;
//    if(self.pageControl) {
//        self.pageControl.currentPage = self.pageControl.currentPage + pageDirection;
//        currentPage = self.pageControl.currentPage;
//    }
//    else if(self.stepper) {
//        self.pageControl.currentPage = self.stepper.value + pageDirection;
//        currentPage = self.stepper.value;
//    }
//    frame.origin.x = self.ctView.frame.size.width * currentPage;
//    frame.origin.y = 0;
//    frame.size = self.ctView.frame.size;
//    [self.ctView scrollRectToVisible:frame animated:YES];
    
}

//plays specified movie
- (void)playMovie:(NSString *)clipPath {
    self.spinnerViews = [CTEUtils startSpinnerOnView:self.view];
    self.player = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:clipPath]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateChanged:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [self.player.moviePlayer prepareToPlay];
}

//plays movie when loaded in
- (void)moviePlayerLoadStateChanged:(NSNotification *)notification {
    NSLog(@"moviePlayerLoadStateChanged");
    MPMovieLoadState loadState = self.player.moviePlayer.loadState;
    if(loadState == MPMovieLoadStatePlayable) {
        NSLog(@"MPMovieLoadStatePlaythroughOK; loading player...");
        [CTEUtils stopSpinnerOnView:self.view withSpinner:self.spinnerViews];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
        [self presentMoviePlayerViewControllerAnimated:self.player];
    }
}

//displays specified image in full-screen image view
- (void)showImage:(UIImage *)image {
    CTEImageViewController *imageView;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        imageView = [[CTEImageViewController alloc]initWithNibName:@"ImageiPhoneView" bundle:nil image:image];
    }
    else {
        imageView = [[CTEImageViewController alloc]initWithNibName:@"ImageiPadView" bundle:nil image:image];
    }
    [self presentViewController:imageView animated:YES completion:nil];
}

//shows/hides nav & toolbars
- (void)toggleUtilityBars {
    BOOL hidden = self.navBar.isHidden;
    [UIView transitionWithView:self.navBar
                      duration:0.25f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    self.navBar.hidden = !hidden;
}

//returns current CTEView chapter based on where the CTEView is at
- (id<CTEChapter>)currentChapter {
    NSNumber *chapterID = [self.cteView currentChapterID];
    id<CTEChapter> retVal = nil;
    for(id<CTEChapter> chapter in self.chapters) {
        NSNumber *matchID = [chapter id];
        if([matchID isEqualToNumber:chapterID]) {
            retVal = chapter;
            break;
        }
    }
    return retVal;
}

//scrolls to appropriate chapter
- (void)setCurrentChapter:(id<CTEChapter>)chapter {
    //do nothing if it's the same chapter
    if(chapter == self.currentChapter) {
        return;
    }
    CGFloat pageWidth = self.cteView.frame.size.width;
    NSNumber *page = [self.cteView pageNumberForChapterID:[chapter id]];
    [self.cteView setContentOffset:CGPointMake(pageWidth * [page intValue], 0.0f) animated:NO];
    [self.cteView setCurrentChapterID:[chapter id]];
}

//TODO other orientations
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
