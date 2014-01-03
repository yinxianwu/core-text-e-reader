//
//  ContentViewController.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEColumnView.h"
#import "CTEContentViewController.h"
#import "CTEViewOptionsViewController.h"
#import "CTEImageViewController.h"
#import "CTEUtils.h"
#import "CTEConstants.h"
#import "CTEMarkupParser.h"
#import "UIViewController+KNSemiModal.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface CTEContentViewController () {
    NSMutableSet *columnsRendered;
}
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
@synthesize barColor;

@synthesize currentChapter;
@synthesize currentFont;
@synthesize currentFontSize;
@synthesize currentColumnsInView = _currentColumnsInView;
@synthesize chapters;
@synthesize attStrings;
@synthesize images;
@synthesize links;

CGFloat const iPhone4OriginOffset = 10.0;
CGFloat const iPhone4HeightOffset = 60.0;
CGFloat const navBarDefaultHeight = 64.0f;
CGFloat const toolBarDefaultHeight = 50.0f;
CGFloat const navBarLegacyHeight = 44.0f;
CGFloat const toolBarLegacyHeight = 80.0f;

//Constructor
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
             chapters:(NSArray *)allChapters
           attStrings:(NSMutableDictionary *)allAttStrings
               images:(NSDictionary *)allImages
                links:(NSDictionary *)allLinks
             barColor:(UIColor *)color {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self.chapters = allChapters;
    self.attStrings = allAttStrings;
    self.images = allImages;
    self.links = allLinks;
    self.barColor = color;
    
    //init the set of rendered columns
    columnsRendered = [NSMutableSet set];
    
    //default column counts depend on device
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.currentColumnsInView = [NSNumber numberWithInt:2];
    }
    else {
        self.currentColumnsInView = [NSNumber numberWithInt:1];
    }

    //TODO this will probably come from a stored cache
    self.currentFont = PalatinoFontKey;
    self.currentFontSize = [NSNumber numberWithInt:18];
    
    return self;
}

//inits the UI elements
- (void)viewDidLoad {
    [super viewDidLoad];

    //height adjustment for first time view is shown
    //this is an issue when displaying on 3.5-inch displays
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        CGRect viewRect = [self.view bounds];
        if(viewRect.size.height > screenRect.size.height) {
            CGRect ctViewFrame = [cteView frame];
            CGRect ctViewNewFrame = CGRectMake(ctViewFrame.origin.x,
                                               ctViewFrame.origin.y - iPhone4OriginOffset,
                                               ctViewFrame.size.width,
                                               screenRect.size.height - iPhone4HeightOffset);
            [cteView setFrame:ctViewNewFrame];
        }
    }

    NSMutableArray *orderedSet = [NSMutableArray arrayWithCapacity:[self.chapters count]];
    for(id<CTEChapter> chapter in self.chapters) {
        [orderedSet addObject:[chapter id]];
    }

    int colCount = [self.currentColumnsInView intValue];
    self.cteView.pageColumnCount = colCount;
    self.cteView.viewDelegate = self;
    [self.cteView setAttStrings:self.attStrings
                         images:self.images
                          links:self.links
                          order:orderedSet];
    [self.cteView buildFrames];
    
    //nav bar init
    BOOL isIOS7 = (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1);
    CGFloat navBarHeight = navBarDefaultHeight;
    CGFloat toolBarHeight = toolBarDefaultHeight;
    UIColor *barBackgroundColor = nil;
    if(isIOS7) {
        [[UINavigationBar appearance] setBarTintColor:self.barColor];
        [[UIToolbar appearance] setBarTintColor:self.barColor];
        barBackgroundColor = [UIColor blackColor];
    }
    else {
        barBackgroundColor = self.barColor;
        navBarHeight = navBarLegacyHeight;
        toolBarHeight = toolBarLegacyHeight;
    }
    NSDictionary *navbarTitleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [UIColor blackColor], NSForegroundColorAttributeName,
                                               nil];
    [[UINavigationBar appearance] setTitleTextAttributes:navbarTitleTextAttributes];
    self.navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, navBarHeight)];
    if(!isIOS7) [navBar setBarStyle:UIBarStyleBlack];
    [self.navBar setDelegate:self];
    [self.navBar setTintColor:barBackgroundColor];
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
    self.pageSlider.continuous = YES;
    [self.pageSlider addTarget:self
                        action:@selector(pageSliderValueChanged:)
              forControlEvents:UIControlEventValueChanged];
    self.sliderAsToolbarItem = [[UIBarButtonItem alloc] initWithCustomView:self.pageSlider];
    
    // Add the items to the toolbar
    [self.toolBar setItems:[NSArray arrayWithObjects:self.sliderAsToolbarItem, self.configButton, nil]];
    [self.toolBar setTintColor:barBackgroundColor];
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

//tell subview to determine initial columns to draw
- (void)viewDidAppear:(BOOL)animated {
    [self.cteView setNeedsDisplay];
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

    self.pageSlider.minimumValue = 0.0f;
    self.pageSlider.maximumValue = [self.cteView totalPages];
    self.pageSlider.value = 0.0f; //TODO this should "sync" to same page
}

//syncs pages to slider value and performs whatever updating/redrawing needed
- (void)pageSliderValueChanged:(id)sender {
    float sliderValue = self.pageSlider.value;
    float sliderPageValue = floorf(sliderValue);
    CGFloat pageWidth = self.cteView.frame.size.width;
    NSNumber *page = [NSNumber numberWithFloat:sliderPageValue];
    [self.cteView setContentOffset:CGPointMake(pageWidth * [page intValue], 0.0f) animated:YES];
    [self.cteView currentChapterNeedsUpdate];
    [self.cteView setNeedsDisplay];
    
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
        popoverView = [[CTEViewOptionsViewController alloc]initWithNibName:@"ViewOptionsiPhoneView"
                                                                    bundle:nil
                                                              selectedFont:self.currentFont
                                                          selectedFontSize:self.currentFontSize
                                                     selectedColumnsInView:self.currentColumnsInView
                                                                  barColor:self.barColor];
        [self presentSemiViewController:popoverView withOptions:@{
                                                              KNSemiModalOptionKeys.pushParentBack : @(NO),
                                                              KNSemiModalOptionKeys.parentAlpha : @(0.8)
                                                              }];
    }
    else {
        popoverView = [[CTEViewOptionsViewController alloc]initWithNibName:@"ViewOptionsiPadView"
                                                                    bundle:nil
                                                              selectedFont:self.currentFont
                                                          selectedFontSize:self.currentFontSize
                                                     selectedColumnsInView:self.currentColumnsInView
                                                                  barColor:self.barColor];
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

    [self.cteView setNeedsDisplay];

//    NSArray *subviews = [self.cteView subviews];
//    for(UIView *subview in subviews) {
//        [subview setNeedsDisplay];
//    }
//    [CATransaction flush];
//    [cteView setNeedsDisplay];
//    [cteView setNeedsLayout];
//    [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate date]];
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

//returns the current set of columns rendered
- (NSMutableSet *)columnsRendered {
    return columnsRendered;
}

//returns columns that should be rendered immediately based on current position
//columns that have already been rendered are NOT included
- (NSArray *)columnsToRenderBasedOnPosition:(CGPoint)position {
    NSMutableArray *columnsToRender = [NSMutableArray array];
    CGPoint currentPosition = [cteView contentOffset];
    CGFloat currentPositionX = currentPosition.x;
    CGSize viewSize = self.view.frame.size;
    CGFloat viewWidth = viewSize.width;
    
    //rule is: column at current position, column before, column after
    //EXCEPT if any of these are already on the list
    NSArray *subviews = [self.cteView subviews];
    for(UIView *subview in subviews) {
        CGRect subviewRect = [self.view convertRect:subview.frame fromView:subview];
        CGFloat subviewStartX = subviewRect.origin.x;
        CGFloat subviewEndX = subviewStartX + subviewRect.size.width;
        if(![columnsRendered member:subview] &&
           (subviewStartX >= currentPositionX - viewWidth) &&
           (subviewEndX < currentPositionX + (viewWidth * 2))) {
            [columnsToRender addObject:subview];
        }
    }

    return columnsToRender;
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

//sets in CTEView
- (void)setCurrentColumnsInView:(NSNumber *)colCount {
    _currentColumnsInView = colCount;
    self.cteView.pageColumnCount = [colCount intValue];
}

//TODO other orientations
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
