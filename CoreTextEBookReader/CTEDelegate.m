//
//  CTEDelegate.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/2/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEDelegate.h"
#import "CTEChapter.h"
#import "CTEConstants.h"
#import "CTEChapterViewController.h"

@implementation CTEDelegate

@synthesize contentViewController;
@synthesize menuViewController;
@synthesize window;

+ (CTEDelegate *)delegateWithWindow:(UIWindow *)appWindow andChapters:(NSArray *)chapters {
    CTEDelegate *delegate = [[CTEDelegate alloc] init];
    if(delegate) {
        delegate.window = appWindow;
        id<CTEChapter> firstChapter = [chapters firstObject];
        
        // create the content view controller that contains detail content
        CTEContentViewController *contentViewCtrlr = nil;
        
        // create the menuViewController so we can swap it in as the
        // windows root view controller whenever required
        CTEMenuViewController *menuViewCtrlr = nil;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            contentViewCtrlr = [[CTEChapterViewController alloc] initWithNibName:@"ChapteriPadView"
                                                                          bundle:nil
                                                                         chapter:firstChapter];
            menuViewCtrlr = [[CTEMenuViewController alloc] initWithNibName:@"MenuiPadView" bundle:nil];
        }
        else {
            contentViewCtrlr = [[CTEChapterViewController alloc] initWithNibName:@"ChapteriPhoneView"
                                                                          bundle:nil
                                                                         chapter:firstChapter];
            menuViewCtrlr = [[CTEMenuViewController alloc] initWithNibName:@"MenuiPhoneView" bundle:nil];
        }
        
        delegate.contentViewController = contentViewCtrlr;
        delegate.menuViewController = menuViewCtrlr;
        delegate.menuViewController.chapterData = chapters;
        
        [[NSNotificationCenter defaultCenter] addObserver:delegate
                                                 selector:@selector(showSideMenu:)
                                                     name:ShowSideMenu
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:delegate
                                                 selector:@selector(hideSideMenu:)
                                                     name:HideSideMenu
                                                   object:nil];
        
        //set the rootViewController to the contentViewController
        delegate.window.rootViewController = delegate.contentViewController;
    }
    
    return delegate;
}

//Side menu actions
- (void)showSideMenu:(NSNotification *)notification {
    //before swaping the views, we'll take a "screenshot" of the current view
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

//Side menu actions
- (void)hideSideMenu:(NSNotification *)notification {
    //all animation takes place elsewhere. When this gets called just swap the contentViewController
    //if a new chapter is chosen, display that one
    id<CTEChapter> chapter = (id<CTEChapter>)[notification object];
    CTEChapterViewController *chapterViewController = (CTEChapterViewController *)self.contentViewController;
    chapterViewController.currentChapter = chapter;
    self.window.rootViewController = self.contentViewController;
}

@end