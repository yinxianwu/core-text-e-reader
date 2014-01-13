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

@implementation CTEManager

@synthesize contentViewController;
@synthesize menuViewController;
@synthesize window;
@synthesize parser;
@synthesize attStrings;
@synthesize images;
@synthesize links;
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
        
        // create the content view controller that contains detail content
        CTEContentViewController *contentViewCtrlr = nil;
        
        // create the menuViewController so we can swap it in as the
        // windows root view controller whenever required
        CTEMenuViewController *menuViewCtrlr = nil;
        
        //create att strs for all chapters
        [CTEManager buildAttStringsForDelegate:manager chapters:chapters notification:nil];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            contentViewCtrlr = [[CTEContentViewController alloc] initWithNibName:@"ContentiPadView"
                                                                          bundle:nil
                                                                        chapters:manager.chapters
                                                                      attStrings:manager.attStrings
                                                                          images:manager.images
                                                                           links:manager.links
                                                                        barColor:manager.barColor];
            menuViewCtrlr = [[CTEMenuViewController alloc] initWithNibName:@"MenuiPadView"
                                                                    bundle:nil
                                                            highlightColor:manager.highlightColor];
        }
        else {
            contentViewCtrlr = [[CTEContentViewController alloc] initWithNibName:@"ContentiPhoneView"
                                                                          bundle:nil
                                                                        chapters:manager.chapters
                                                                      attStrings:manager.attStrings
                                                                          images:manager.images
                                                                           links:manager.links
                                                                        barColor:manager.barColor];
            menuViewCtrlr = [[CTEMenuViewController alloc] initWithNibName:@"MenuiPhoneView"
                                                                    bundle:nil
                                                            highlightColor:manager.highlightColor];
        }
        
        manager.contentViewController = contentViewCtrlr;
        manager.menuViewController = menuViewCtrlr;
        manager.menuViewController.chapterData = chapters;
        
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
        
        //set the rootViewController to the contentViewController
        manager.window.rootViewController = manager.contentViewController;
    }
    
    return manager;
}

//Parses all chapters and builds appropriate att strings using delegate settings
//if no NSNotification is specified, builds with default view options settings
+ (void)buildAttStringsForDelegate:(CTEManager *)delegate
                          chapters:(NSArray *)chapters
                      notification:(NSNotification *)notification {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if(notification && delegate.parser) {
        if([[notification name] isEqualToString:ChangeFont]) {
            NSString *fontKey = (NSString *)[notification object];
            delegate.contentViewController.currentFont = fontKey;
            delegate.parser.currentBodyFont = fontKey;
        }
        else if([[notification name] isEqualToString:ChangeFontSize]) {
            NSNumber *fontSize = (NSNumber *)[notification object];
            delegate.contentViewController.currentFontSize = fontSize;
            delegate.parser.currentBodyFontSize = [fontSize floatValue];
        }
        else if([[notification name] isEqualToString:ChangeColumnCount]) {
            NSNumber *columnCount = (NSNumber *)[notification object];
            delegate.contentViewController.currentColumnsInView = columnCount;
        }

    }
    else {
        delegate.parser = [[CTEMarkupParser alloc] init];
    }
    
    delegate.attStrings = [NSMutableDictionary dictionaryWithCapacity:[chapters count]];
    delegate.images = [NSMutableDictionary dictionaryWithCapacity:[chapters count]];
    delegate.links = [NSMutableDictionary dictionaryWithCapacity:[chapters count]];
    for(id<CTEChapter>chapter in chapters) {
        NSAttributedString *contentAttStr = [delegate.parser attrStringFromMarkup:[chapter body]
                                                                       screenSize:screenRect];
        [delegate.attStrings setObject:contentAttStr forKey:[chapter id]];
        [delegate.images setObject:delegate.parser.images forKey:[chapter id]];
        [delegate.links setObject:delegate.parser.links forKey:[chapter id]];
        [delegate.parser resetParser];
    }
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
    [CTEManager buildAttStringsForDelegate:self chapters:self.chapters notification:notification];
    [self.contentViewController rebuildContent:self.attStrings images:self.images links:self.links];
}

@end