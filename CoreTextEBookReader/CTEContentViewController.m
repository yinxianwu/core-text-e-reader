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
    BOOL isFirstLoad;
    BOOL programmaticScroll;
    BOOL updateTextPosition;
    NSNumber *initialPageNum;
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

@synthesize currentChapter = _currentChapter;
@synthesize currentFont;
@synthesize currentFontSize;
@synthesize currentTextPosition;
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
             barColor:(UIColor *)color {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self.barColor = color;
    self.currentTextPosition = 0; //initialize
    isFirstLoad = YES;
    programmaticScroll = NO;
    updateTextPosition = YES;
    
    //init the set of rendered columns
    columnsRendered = [NSMutableSet set];
    
    //default column counts depend on device
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.currentColumnsInView = [NSNumber numberWithInt:2];
    }
    else {
        self.currentColumnsInView = [NSNumber numberWithInt:1];
    }
    
    return self;
}

//inits the UI elements
- (void)viewDidLoad {
    [super viewDidLoad];

    //height adjustment for first time view is shown
    //this is an issue when displaying on 3.5-inch displays
    //FIXME views should handle this
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

    self.cteView.currentFont = self.currentFont;
    self.cteView.currentFontSize = [self.currentFontSize floatValue];
    int colCount = [self.currentColumnsInView intValue];
    self.cteView.currentColumnCount = colCount;
    self.cteView.viewDelegate = self;
    
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
    self.pageSlider.continuous = NO;
    [self.pageSlider addTarget:self
                        action:@selector(pageSliderValueChanged:)
              forControlEvents:UIControlEventValueChanged];
    self.sliderAsToolbarItem = [[UIBarButtonItem alloc] initWithCustomView:self.pageSlider];
    
    // Add the items to the toolbar
    [self.toolBar setItems:[NSArray arrayWithObjects:self.sliderAsToolbarItem, self.configButton, nil]];
    [self.toolBar setTintColor:barBackgroundColor];
    [self.view addSubview:self.toolBar];
    
    //listen for page turn events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePageForward:)
                                                 name:PageForward
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePageBackward:)
                                                 name:PageBackward
                                               object:nil];
}

//some component sizing on initial load
//per http://stackoverflow.com/questions/5066847/get-the-width-of-a-uibarbuttonitem
- (void)viewWillAppear:(BOOL)animated {
    if(isFirstLoad) {
        UIBarButtonItem *item = self.configButton;
        UIView *view = [item valueForKey:@"view"];
        CGFloat width = view ? [view frame].size.width : (CGFloat)0.0;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        [self.sliderAsToolbarItem setWidth:screenWidth - width - 40]; //adjust for borders and such
        isFirstLoad = NO;
    }
    
    //get user settings, if any
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [rootPath stringByAppendingPathComponent:SettingsFileName];
    NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];

    //no file -- create one and use initial defaults
    if(!plistDict) {
        self.currentFont = PalatinoFontKey;
        self.currentFontSize = [NSNumber numberWithInt:18];
        [self saveSettings];
    }
    //update with contents of file
    else {
        self.currentFont = (NSString *)[plistDict objectForKey:BodyFontKey];
        self.currentFontSize = (NSNumber *)[plistDict objectForKey:BodyFontSizeKey];
        self.currentColumnsInView = (NSNumber *)[plistDict objectForKey:ColumnCountKey];
        initialPageNum = (NSNumber *)[plistDict objectForKey:PageNumKey];
    }
    
    //notifies receivers to provide content
    [[NSNotificationCenter defaultCenter] postNotificationName:ContentViewLoaded object:self];
}

//Shows wait spinner; if one is already up, does nothing
- (void)showWaitSpinner {
    if(!self.spinnerViews) {
        self.spinnerViews = [CTEUtils startSpinnerOnView:self.view];
    }
}

//Hides wait spinner; if none are displaying, does nothing
- (void)hideWaitSpinner {
    if(self.spinnerViews) {
        [CTEUtils stopSpinnerOnView:self.view withSpinner:self.spinnerViews];
        self.spinnerViews = nil;
    }
}


- (void)saveSettings {
    NSString *error = nil;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [rootPath stringByAppendingPathComponent:SettingsFileName];
    NSMutableDictionary *newPlistDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         self.currentFont,BodyFontKey,
                                         self.currentFontSize,BodyFontSizeKey,
                                         self.currentColumnsInView,ColumnCountKey,
                                         [NSNumber numberWithInt:[self getCurrentPage]],PageNumKey,
                                         nil];
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:(id)newPlistDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                         errorDescription:&error];
    [plistData writeToFile:filePath atomically:YES];
}

//rebuilds content with current data
- (void)rebuildContent:(NSMutableDictionary *)allAttStrings
                images:(NSDictionary *)allImages
                 links:(NSDictionary *)allLinks {
    self.attStrings = allAttStrings;
    self.images = allImages;
    self.links = allLinks;
    [self.cteView clearFrames];
    NSMutableArray *orderedSet = [NSMutableArray array];
    for(id<CTEChapter> chapter in self.chapters) {
        [orderedSet addObject:[chapter id]];
    }
    
    self.cteView.currentFont = self.currentFont;
    self.cteView.currentFontSize = [self.currentFontSize floatValue];
    int colCount = [self.currentColumnsInView intValue];
    self.cteView.currentColumnCount = colCount;
    [self.cteView setAttStrings:self.attStrings
                         images:self.images
                          links:self.links
                          order:orderedSet];
    [self.cteView buildFrames];

    self.pageSlider.minimumValue = 0.0f;
    self.pageSlider.maximumValue = [self.cteView totalPages];
    
    //if an initial page number was loaded in from settings, use that then nil it out
    if(initialPageNum) {
        self.pageSlider.value = [initialPageNum floatValue];
        [self scrollToPage:[initialPageNum intValue] animated:NO updateCurrentTextPosition:YES];
        initialPageNum = nil;
    }
    else {
        self.pageSlider.value = [self.cteView pageNumberForTextPosition:self.currentTextPosition];
    }
}

//syncs pages to slider value and performs whatever updating/redrawing needed
- (void)pageSliderValueChanged:(id)sender {
    float sliderValue = self.pageSlider.value;
    float sliderPageValue = floorf(sliderValue);
    CGRect cteViewFrame = self.cteView.frame;
    cteViewFrame.origin.x = cteViewFrame.size.width * sliderPageValue;
    cteViewFrame.origin.y = 0;
    [self.cteView scrollRectToVisible:cteViewFrame animated:NO];
    [self.cteView currentChapterNeedsUpdate];
    [self.cteView setNeedsDisplay];
    self.currentTextPosition = [self.cteView getCurrentTextPosition];
    
    //update navbar title to new chapter title
    UINavigationItem *item = (UINavigationItem *)[self.navBar.items objectAtIndex:0];
    item.title = [self.currentChapter title];
    
    //update settings file
    [self saveSettings];
}

//side menu action
- (void)slideMenuButtonTouched:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ShowSideMenu object:self];
}

//brings up settings popover
- (void)configButtonTouched:(id)sender {
    //TODO if button is pushed when a popover is already visible, app crashes!
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

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
    CGRect viewFrameInWindow = [self.view convertRect:self.view.bounds toView:nil];
    CGFloat endX = viewFrameInWindow.origin.x + viewFrameInWindow.size.width;
    CGPoint locationInWindow = [touch locationInView:nil];
    CGFloat pageTurnBoundary = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ?
                               PageTurnBoundaryPhone :
                               PageTurnBoundaryPad;
    
    //if it's anywhere within range of left or right edge, consider that a page turn request
    if(locationInWindow.x < pageTurnBoundary) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PageBackward object:self];
    }
    else if(locationInWindow.x > (endX - pageTurnBoundary)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PageForward object:self];
    }
}

//event handler
-(void)handlePageForward:(id)sender {
    [self nextPage];
}

//event handler
-(void)handlePageBackward:(id)sender {
    [self prevPage];
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
    self.currentTextPosition = [self.cteView getCurrentTextPosition];
    
    //update settings file
    [self saveSettings];
}

//post-programmatic animations
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [cteView currentChapterNeedsUpdate];
    
    //update navbar title to new chapter title
    UINavigationItem *item = (UINavigationItem *)[self.navBar.items objectAtIndex:0];
    item.title = [self.currentChapter title];
    
    //update settings file
    [self saveSettings];
}

//Updates the view in response to a programmatic scroll
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(programmaticScroll) {
        programmaticScroll = NO;
        [self.cteView currentChapterNeedsUpdate];
        [self.cteView setNeedsDisplay];
        
        //cache for format changes, if applicable
        if(updateTextPosition) {
            self.currentTextPosition = [self.cteView getCurrentTextPosition];
        }
        
        //update navbar title to new chapter title
        UINavigationItem *item = (UINavigationItem *)[self.navBar.items objectAtIndex:0];
        item.title = [self.currentChapter title];
        
        //update settings file
        [self saveSettings];
        
        //repaint
        [self.cteView setNeedsDisplay];
    }
}

//plays specified movie
- (void)playMovie:(NSString *)clipPath {
    [self showWaitSpinner];
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
        [self hideWaitSpinner];
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

- (void)nextPage {
    int pageNb = [cteView getCurrentPage] + 1;
    if(pageNb < cteView.totalPages) {
        [self scrollToPage:pageNb animated:YES updateCurrentTextPosition:YES];
    }
}

- (void)prevPage {
    int pageNb = [cteView getCurrentPage] - 1;
    if(pageNb >= 0) {
        [self scrollToPage:pageNb animated:YES updateCurrentTextPosition:YES];
    }
}

//Programmatically scrolls to specified page, animating and updating as specified
- (void)scrollToPage:(int)page animated:(BOOL)animated updateCurrentTextPosition:(BOOL)shouldUpdate {
    //if it's same page, simply redraw
    int prevPage = [self getCurrentPage];
    if(prevPage == page) {
        [self.cteView setNeedsDisplay];
        return;
    }
    
    //flip flags
    updateTextPosition = shouldUpdate;
    programmaticScroll = YES;
    
    CGRect cteViewFrame = self.cteView.frame;
    CGFloat newOriginX = cteViewFrame.size.width * page;
    CGRect scrollToFrame = CGRectMake(newOriginX, cteViewFrame.origin.y, cteViewFrame.size.width, cteViewFrame.size.height);
    [self.cteView scrollRectToVisible:scrollToFrame animated:animated];
}

//Returns current page index
//convenience method
- (int)getCurrentPage {
    return [self.cteView getCurrentPage];
}

//Returns page number for specified text position
//convenience method
- (int)pageForTextPosition:(int)position {
    return [self.cteView pageNumberForTextPosition:position];
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
    CGSize viewSize = cteView.frame.size;
    CGFloat viewWidth = viewSize.width;
    CGFloat prevPageStartX = currentPositionX - viewWidth;
    CGFloat nextPageEndX = currentPositionX + (viewWidth * 2);
    
    //rule is: column at current position, column before, column after
    //EXCEPT if any of these are already on the list
    NSArray *subviews = [self.cteView subviews];
    for(UIView *subview in subviews) {
        CGRect subviewFrame = subview.frame;
        CGFloat subviewStartX = subviewFrame.origin.x;
        CGFloat subviewEndX = subviewStartX + subviewFrame.size.width;
        if([subview isKindOfClass:[CTEColumnView class]] &&
           ![columnsRendered member:subview] &&
           (subviewStartX >= prevPageStartX) &&
           (subviewEndX < nextPageEndX)) {
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
    
    _currentChapter = retVal;
    return retVal;
}

//scrolls to appropriate chapter
- (void)setCurrentChapter:(id<CTEChapter>)chapter {
    //do nothing if it's the same chapter
    if(chapter == self.currentChapter) {
        return;
    }
    NSNumber *page = [self.cteView pageNumberForChapterID:[chapter id]];
    [self scrollToPage:[page intValue] animated:NO updateCurrentTextPosition:YES];
}

//sets in CTEView
- (void)setCurrentColumnsInView:(NSNumber *)colCount {
    _currentColumnsInView = colCount;
    self.cteView.currentColumnCount = [colCount intValue];
}

//current column count
- (NSNumber *)currentColumnsInView {
    return _currentColumnsInView;
}

//TODO other orientations
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

@end
