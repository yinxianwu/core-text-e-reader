//
//  ContentViewController.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEContentViewController.h"
#import "CTEViewOptionsViewController.h"
#import "CTEImageViewController.h"
#import "CTEUtils.h"
#import "CTEConstants.h"
#import "CTEMarkupParser.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface CTEContentViewController ()
@property (nonatomic, strong) NSArray *spinnerViews;
@end

@implementation CTEContentViewController

@synthesize cteView;
@synthesize navBar;
@synthesize toolBar;
@synthesize spinnerViews;
@synthesize moviePlayerController;
@synthesize pageSlider;
@synthesize configButton;
@synthesize sliderAsToolbarItem;
@synthesize popoverController;

@synthesize currentChapter;
@synthesize currentFont;
@synthesize currentFontSize;
@synthesize currentColumnsInView;
@synthesize chapters;
@synthesize attStrings;
@synthesize images;
@synthesize links;

//Constructor
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
             chapters:(NSArray *)allChapters
           attStrings:(NSMutableDictionary *)allAttStrings
               images:(NSDictionary *)allImages
                links:(NSDictionary *)allLinks {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self.chapters = allChapters;
    self.attStrings = allAttStrings;
    self.images = allImages;
    self.links = allLinks;
    
    //TODO this will probably come from somewhere else
    self.currentColumnsInView = [NSNumber numberWithInt:2];
    self.currentFont = PalatinoFontKey;
    self.currentFontSize = [NSNumber numberWithInt:18];
    
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

    //color for bars
    //TODO make configurable
    CGFloat red = 225.0f/255.0f;
    CGFloat green = 210.0f/255.0f;
    CGFloat blue = 169.0f/255.0f;
    UIColor *barTintColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
    
    //nav bar init
    BOOL isIOS7 = (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1);
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    CGFloat navBarHeight = 64.0f;
    CGFloat toolBarHeight = 50.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        //height adjustment for first time view is shown
        //this is an issue when displaying on 3.5-inch displays
        CGRect viewRect = [self.view bounds];
        if(viewRect.size.height > screenRect.size.height) {
            CGRect ctViewRect = [cteView bounds];
            CGRect ctViewNewRect = CGRectMake(ctViewRect.origin.x,
                                              ctViewRect.origin.y,
                                              ctViewRect.size.width,
                                              screenRect.size.height - 88);
            [cteView setFrame:ctViewNewRect];
        }
    }
    UIColor *barColor = nil;
    if(isIOS7) {
        [[UINavigationBar appearance] setBarTintColor:barTintColor];
        [[UIToolbar appearance] setBarTintColor:barTintColor];
        barColor = [UIColor blackColor];
    }
    else {
        barColor = barTintColor;
        navBarHeight -= 20.0f;
        toolBarHeight += 30.0f;
    }
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor blackColor], NSForegroundColorAttributeName,
//                                               [UIColor blackColor], UITextAttributeTextShadowColor,
//                                               [NSValue valueWithUIOffset:UIOffsetMake(-1, 0)], UITextAttributeTextShadowOffset,
                                               nil];
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, navBarHeight)];
    if(!isIOS7) [navBar setBarStyle:UIBarStyleBlack];
    [self.navBar setDelegate:self];
    [self.navBar setTintColor:barColor];
    [self.view addSubview:self.navBar];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
                                  initWithImage:[UIImage imageNamed:@"ThreeLines.png"]
                                  style:UIBarButtonItemStyleBordered
                                  target:self
                                  action:@selector(slideMenuButtonTouched:)];
    NSString *navBarInitialTitle = NavigationBarTitle;
    if([self.chapters count] > 0) {
        id<CTEChapter> firstChapter = (id<CTEChapter>)[self.chapters firstObject];
        navBarInitialTitle = [firstChapter title];
    }
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:navBarInitialTitle];
    item.leftBarButtonItem = addButton;
    [self.navBar pushNavigationItem:item animated:false];
    
    //toolbar and its widgets init
    self.toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, screenHeight - toolBarHeight, screenWidth, toolBarHeight)];
    self.configButton = [[UIBarButtonItem alloc] initWithTitle:@"Aa"
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(configButtonTouched:)];
    [self.configButton setTitleTextAttributes:@{UITextAttributeFont: [UIFont fontWithName:@"Helvetica-Bold" size:26.0],
                                      UITextAttributeTextColor: [UIColor darkGrayColor]}
                                forState:UIControlStateNormal];
    
    self.pageSlider = [[UISlider alloc] init];
    self.pageSlider.minimumValue = 0.0f;
    self.pageSlider.maximumValue = [self.cteView totalPages];
    [self.pageSlider addTarget:self
                        action:@selector(pageSliderValueChanged:)
              forControlEvents:UIControlEventValueChanged];
    self.sliderAsToolbarItem = [[UIBarButtonItem alloc] initWithCustomView:self.pageSlider];
    
    // Add the items to the toolbar
    [self.toolBar setItems:[NSArray arrayWithObjects:self.sliderAsToolbarItem, self.configButton, nil]];
    [self.toolBar setTintColor:barColor];
    [self.view addSubview:self.toolBar];
}

//some component sizing
//per http://stackoverflow.com/questions/5066847/get-the-width-of-a-uibarbuttonitem
- (void)viewWillAppear:(BOOL)animated {
    UIBarButtonItem *item = self.configButton;
    UIView *view = [item valueForKey:@"view"];
    CGFloat width = view ? [view frame].size.width : (CGFloat)0.0;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    [self.sliderAsToolbarItem setWidth:screenWidth - width - 40]; //adjust for borders and such
}

//rebuilds content with current data
- (void)rebuildContent:(NSMutableDictionary *)allAttStrings
                images:(NSDictionary *)allImages
                 links:(NSDictionary *)allLinks {
    self.attStrings = allAttStrings;
    self.images = allImages;
    self.links = allLinks;
    [self.cteView clearFrames];
    NSMutableArray *orderedSet = [NSMutableArray arrayWithCapacity:[self.chapters count]];
    for(id<CTEChapter> chapter in self.chapters) {
        [orderedSet addObject:[chapter id]];
    }
    
    [self.cteView setAttStrings:self.attStrings
                         images:self.images
                          links:self.links
                          order:orderedSet];
    [self.cteView buildFrames];

}

//syncs pages to slider value
- (void)pageSliderValueChanged:(id)sender {
    float sliderValue = self.pageSlider.value;
    float sliderPageValue = floorf(sliderValue);
    CGFloat pageWidth = self.cteView.frame.size.width;
    NSNumber *page = [NSNumber numberWithFloat:sliderPageValue];
    [self.cteView setContentOffset:CGPointMake(pageWidth * [page intValue], 0.0f) animated:YES];
    [self.cteView currentChapterNeedsUpdate];
    
    //update navbar title to new chapter title
    UINavigationItem *item = (UINavigationItem *)[self.navBar.items objectAtIndex:0];
    item.title = [self.currentChapter title];
}

//side menu action
- (void)slideMenuButtonTouched:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ShowSideMenu object:self];
}

//brings up settings popover
- (void)configButtonTouched:(id)sender {
    CTEViewOptionsViewController *popoverView;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        //TODO with iPhone it's gonna be a separate modal view
    }
    else {
        popoverView = [[CTEViewOptionsViewController alloc]initWithNibName:@"ViewOptionsiPadView"
                                                                    bundle:nil
                                                              selectedFont:self.currentFont
                                                          selectedFontSize:[NSNumber numberWithInt:18]
                                                     selectedColumnsInView:[NSNumber numberWithInt:2]]; //TODO will come from parser
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:popoverView];
        [self.popoverController presentPopoverFromBarButtonItem:self.configButton
                                  permittedArrowDirections:UIPopoverArrowDirectionAny
                                                  animated:YES];
    }
}

//post user-initated scroll
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [cteView currentChapterNeedsUpdate];
    
    //update page slider to selected page
    [self.pageSlider setValue:[cteView getCurrentPage]];
    
    //update navbar title to new chapter title
    UINavigationItem *item = (UINavigationItem *)[self.navBar.items objectAtIndex:0];
    item.title = [self.currentChapter title];
}

//post-programmatic animations
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [cteView currentChapterNeedsUpdate];
    
    //update navbar title to new chapter title
    UINavigationItem *item = (UINavigationItem *)[self.navBar.items objectAtIndex:0];
    item.title = [self.currentChapter title];
}

//plays specified movie
- (void)playMovie:(NSString *)clipPath {
    self.spinnerViews = [CTEUtils startSpinnerOnView:self.view];
    self.moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:clipPath]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateChanged:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [self.moviePlayerController.moviePlayer prepareToPlay];
}

//plays movie when loaded in
- (void)moviePlayerLoadStateChanged:(NSNotification *)notification {
    NSLog(@"moviePlayerLoadStateChanged");
    MPMovieLoadState loadState = self.moviePlayerController.moviePlayer.loadState;
    if(loadState == MPMovieLoadStatePlayable) {
        NSLog(@"MPMovieLoadStatePlaythroughOK; loading player...");
        [CTEUtils stopSpinnerOnView:self.view withSpinner:self.spinnerViews];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
        [self presentMoviePlayerViewControllerAnimated:self.moviePlayerController];
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
    [UIView transitionWithView:self.toolBar
                      duration:0.25f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:NULL
                    completion:NULL];
    self.toolBar.hidden = !hidden;
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
    
    //update page slider to selected page
    [self.pageSlider setValue:[page floatValue]];
    
    //update navbar title to chapter title
    UINavigationItem *item = (UINavigationItem *)[self.navBar.items objectAtIndex:0];
    item.title = [chapter title];
}

//TODO other orientations
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
