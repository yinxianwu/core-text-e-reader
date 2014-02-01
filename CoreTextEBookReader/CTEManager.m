//
//  CTEDelegate.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/2/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEManager.h"
#import "CTEChapter.h"
#import "CTEConstants.h"
#import "CTEContentViewController.h"
#import "FormatSelectionInfo.h"

@implementation CTEManager

@synthesize contentViewController;
@synthesize menuViewController;
@synthesize window;
@synthesize parser;
@synthesize chapters;
@synthesize barColor;
@synthesize highlightColor;

+ (CTEManager *)managerWithWindow:(UIWindow *)appWindow
                        andChapters:(NSArray *)chapters
                        andBarColor:(UIColor *)color
                  andHighlightColor:(UIColor *)highlight {
    CTEManager *manager = [[CTEManager alloc] init];
    if(manager) {
        manager.window = appWindow;
        manager.chapters = chapters;
        manager.barColor = color;
        manager.highlightColor = highlight;
        
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(sideMenuWillBeShown:)
                                                     name:ShowSideMenu
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(sideMenuWasHidden:)
                                                     name:HideSideMenu
                                                   object:nil];
        //listen for view option changes
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(contentViewOptionsUpdated:)
                                                     name:ContentViewLoaded
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(contentViewOptionsUpdated:)
                                                     name:ChangeFont
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(contentViewOptionsUpdated:)
                                                     name:ChangeFontSize
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(contentViewOptionsUpdated:)
                                                     name:ChangeColumnCount
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(contentViewOptionsUpdated:)
                                                     name:ChangeFormat
                                                   object:nil];
        
        NSString *contentNibName = nil;
        NSString *menuNibName = nil;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            contentNibName = @"ContentiPadView";
            menuNibName = @"MenuiPadView";
        }
        else {
            contentNibName = @"ContentiPhoneView";
            menuNibName = @"MenuiPhoneView";
        }
        
        manager.contentViewController = [[CTEContentViewController alloc] initWithNibName:contentNibName
                                                                      bundle:nil
                                                                    barColor:manager.barColor];
        manager.menuViewController = [[CTEMenuViewController alloc] initWithNibName:menuNibName
                                                                bundle:nil
                                                        highlightColor:manager.highlightColor];
        manager.menuViewController.chapterData = chapters;
        manager.contentViewController.chapters = chapters;
        
        //set the rootViewController to the contentViewController
        manager.window.rootViewController = manager.contentViewController;
    }
    
    return manager;
}

- (void)buildAttStrings:(NSNotification *)notification {
    if(!self.parser) {
        self.parser = [[CTEMarkupParser alloc] init];
    }
    
    if(notification) {
        if([[notification name] isEqualToString:ChangeFont]) {
            NSString *fontName = (NSString *)[notification object];
            self.contentViewController.currentFont = fontName;
            self.parser.currentBodyFont = fontName;
        }
        else if([[notification name] isEqualToString:ChangeFontSize]) {
            NSNumber *fontSizeObj = (NSNumber *)[notification object];
            self.contentViewController.currentFontSize = fontSizeObj;
            self.parser.currentBodyFontSize = [fontSizeObj floatValue];
        }
        else if([[notification name] isEqualToString:ChangeColumnCount]) {
            NSNumber *columnCountObj = (NSNumber *)[notification object];
            self.contentViewController.currentColumnsInView = columnCountObj;
        }
        //iPhone only -- all-in-one format changes
        else if([[notification name] isEqualToString:ChangeFormat]) {
            NSDictionary *formatInfo = (NSDictionary *)[notification object];
            for(id key in formatInfo) {
                if([key isEqualToString:ChangeFont]) {
                    NSString *fontName = (NSString *)[formatInfo objectForKey:key];
                    self.contentViewController.currentFont = fontName;
                    self.parser.currentBodyFont = fontName;
                }
                if([key isEqualToString:ChangeFontSize]) {
                    NSNumber *fontSizeObj = (NSNumber *)[formatInfo objectForKey:key];
                    self.contentViewController.currentFontSize = fontSizeObj;
                    self.parser.currentBodyFontSize = [fontSizeObj floatValue];
                }
            }
        }
    }
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        NSMutableDictionary *allAttStrings = [NSMutableDictionary dictionaryWithCapacity:[self.chapters count]];
        NSMutableDictionary *allImages = [NSMutableDictionary dictionaryWithCapacity:[self.chapters count]];
        NSMutableDictionary *allLinks = [NSMutableDictionary dictionaryWithCapacity:[self.chapters count]];
        for(id<CTEChapter>chapter in self.chapters) {
            [self.parser resetParser];
            NSAttributedString *contentAttStr = [self.parser attrStringFromMarkup:[chapter body]
                                                                          screenSize:screenRect];
            [allAttStrings setObject:contentAttStr forKey:[chapter id]];
            [allImages setObject:self.parser.images forKey:[chapter id]];
            [allLinks setObject:self.parser.links forKey:[chapter id]];
        }
        
        //all done -- notify main thread it's OK to redraw
        //wrap all layout data in an NSArray
        //TODO might be better as an object?
        NSArray *contentData = [NSArray arrayWithObjects:allAttStrings, allImages, allLinks, nil];
        [self performSelectorOnMainThread:@selector(rebuildContentView:) withObject:contentData waitUntilDone:YES];
    }];
    [queue addOperation:operation];
}

- (void)rebuildContentView:(NSArray *)contentData {
    int currentTextPosition = self.contentViewController.currentTextPosition;
    
    //unpack contentData and pass to content view controller
    NSMutableDictionary *allAttStrings = (NSMutableDictionary *)[contentData objectAtIndex:0];
    NSMutableDictionary *allImages = (NSMutableDictionary *)[contentData objectAtIndex:1];
    NSMutableDictionary *allLinks = (NSMutableDictionary *)[contentData objectAtIndex:2];
    [self.contentViewController rebuildContent:allAttStrings images:allImages links:allLinks];
    
    //get new page from current position, which doesn't change until user changes the page
    //this prevents pages from "hopping" as users toggle back and forth thru different styles,
    //which if it reset the currentTextPosition every time would possibly cause pages to misalign
    //this is more a consistency thing but it makes for a more pleasing flow
    NSString *font = self.contentViewController.currentFont;
    float fontSize = [self.contentViewController.currentFontSize floatValue];
    int columnCount = [self.contentViewController.currentColumnsInView intValue];
    FormatSelectionInfo *info = [FormatSelectionInfo sharedInstance];
    int newCurrentPage = [info getPageForLocation:currentTextPosition
                                             font:font
                                             size:fontSize
                                      columnCount:columnCount];
    if(newCurrentPage == -1) {
        newCurrentPage = [self.contentViewController pageForTextPosition:currentTextPosition];
    }
    [self.contentViewController scrollToPage:newCurrentPage animated:NO updateCurrentTextPosition:NO];
}

//Selects appropriate chapter then does side menu reveal
- (void)sideMenuWillBeShown:(NSNotification *)notification {
    //determine the current chapter and update menu view accordingly
    if([[notification object] isKindOfClass:[CTEContentViewController class]]) {
        CTEContentViewController *contentView = (CTEContentViewController *)[notification object];
        id<CTEChapter> chapter = contentView.currentChapter;
        long selectedRow = [self.contentViewController.chapters indexOfObject:chapter];
        [self.menuViewController setCurrentChapterIndex:[NSNumber numberWithLong:selectedRow]];
    }
    
    //before swapping the views, we'll take a "screenshot" of the current view
    //by rendering its CALayer into the an ImageContext then saving that off to a UIImage
    CGSize viewSize = self.contentViewController.view.bounds.size;
    UIGraphicsBeginImageContextWithOptions(viewSize, NO, 1.0);
    CALayer *layer = self.contentViewController.view.layer;
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    
    //Read the UIImage object
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //pass this image off to the MenuViewController then swap it in as the rootViewController
    self.menuViewController.screenShotImage = image;
    self.window.rootViewController = self.menuViewController;
}

//Scrolls to new chapter
- (void)sideMenuWasHidden:(NSNotification *)notification {
    //all animation takes place elsewhere. When this gets called just swap the contentViewController
    //if a new chapter is chosen, display that one
    id<CTEChapter> chapter = (id<CTEChapter>)[notification object];
    [self.contentViewController setCurrentChapter:chapter];
    self.window.rootViewController = self.contentViewController;
}

//Updates attributed Strings for content, then applies them to content view
- (void)contentViewOptionsUpdated:(NSNotification *)notification {
    [self buildAttStrings:notification];
}

@end
