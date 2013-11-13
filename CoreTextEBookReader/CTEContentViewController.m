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
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface CTEContentViewController ()
@property (nonatomic, strong) NSArray *spinnerViews;
@property (nonatomic) float decelOffsetX;
@end

@implementation CTEContentViewController

//@synthesize previousChapter = _previousChapter;

@synthesize cteView;
//@synthesize pageControl;
//@synthesize stepper;
//@synthesize parser;
@synthesize spinnerViews;
@synthesize decelOffsetX;
//@synthesize currentPageLabel;
//@synthesize pagesRemainingLabel;
@synthesize navBar;

@synthesize currentChapter = _currentChapter;
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
//    _currentChapter = chapter;
//    self.parser = [[CTEMarkupParser alloc] init];
    self.decelOffsetX = 0.0f;
    
    return self;
}

//inits the UI elements
- (void)viewDidLoad {
    [super viewDidLoad];
    
    _currentChapter = (id<CTEChapter>)[self.chapters firstObject];
    NSAttributedString *attStringForChapter = (NSAttributedString *)[self.attStrings objectForKey:[_currentChapter id]];
    NSArray *imagesForChapter = (NSArray *)[self.images objectForKey:[_currentChapter id]];
    NSArray *linksForChapter = (NSArray *)[self.links objectForKey:[_currentChapter id]];
    
    [self.cteView setAttString:attStringForChapter
                    withImages:imagesForChapter
                      andLinks:linksForChapter];
    [self.cteView buildFrames];

    BOOL isIOS7 = (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1);
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat navBarHeight = 0.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        navBarHeight = 64;
        
        //height adjustment for first time view is shown
        //this is an issue when displaying on 3.5-inch displays
        CGRect viewRect = [self.view bounds];
        if(viewRect.size.height > screenRect.size.height) {
            CGRect ctViewRect = [cteView bounds];
            CGRect ctViewNewRect = CGRectMake(ctViewRect.origin.x, ctViewRect.origin.y, ctViewRect.size.width, screenRect.size.height - 88);
            [cteView setFrame:ctViewNewRect];
        }
    }
    else {
        navBarHeight = 64;
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

//Load data into view
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    //don't reload if it's the same chapter
//    if(self.previousChapter == self.currentChapter) {
//        return;
//    }
    
    //nav bar title
    UINavigationItem *navItem = [[navBar items] objectAtIndex:0];
//    [navItem setTitle:_currentChapter.title];
    
//    CGRect screenRect = [[UIScreen mainScreen] bounds];
//    [ctView clearFrames];
//    [parser resetParser];
    
    //parse to derive attributed string
//    NSAttributedString *attString = [parser attrStringFromMarkup:self.currentChapter.body screenSize:screenRect];
//    self.ctView.modalTarget = self; //TODO this should be redone as delegate pattern
//    [self.ctView setAttString:attString withImages:parser.images andLinks:parser.links];
//    [self.ctView buildFrames];
    
//    //different impls for paging
//    if(self.pageControl) {
//        self.pageControl.numberOfPages = [ctView totalPages];
//        self.pageControl.currentPage = 0;
//    }
//    else if(self.stepper) {
//        self.stepper.maximumValue = [ctView totalPages];
//        self.stepper.minimumValue = 0.0;
//        self.stepper.value = 0.0;
//    }
//    
//    //init page labels
//    NSString *pagesRemaining = [NSString stringWithFormat:@"%d", [ctView totalPages]];
//    [currentPageLabel setText:@"1"];
//    [pagesRemainingLabel setText:pagesRemaining];
}

//if an image view, caches the current index to prevent reloads
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^)(void))completion NS_AVAILABLE_IOS(5_0) {
    if([viewControllerToPresent isKindOfClass:[CTEImageViewController class]]) {
        [self setContentIndex:self.contentIndex];
    }
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}


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

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    self.decelOffsetX = self.cteView.contentOffset.x;
}

//performs column redraw
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    int totalPages = [ctView totalPages];
//    int currentPage = self.pageControl.currentPage;
//    float currentOffsetX = self.ctView.contentOffset.x;
//    if(decelOffsetX < currentOffsetX && (currentPage + 1 == totalPages)) {
//        NSLog(@"END CHAPTER");
//    }
//    [ctView redrawFrames];
}

//performs column redraw
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
//    [ctView redrawFrames];
}

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

//sets current chapter and caches previous
//- (void)setCurrentChapter:(id<CTEChapter>) chapter {
//    _previousChapter = _currentChapter;
//    _currentChapter = chapter;
//}

//TODO other orientations
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
