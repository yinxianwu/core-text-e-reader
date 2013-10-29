//
//  CTEAppDelegate.m
//  SampleApp
//
//  Created by David Jedeikin on 10/27/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEConstants.h"
#import "CTESampleChapter.h"
#import "CTEAppDelegate.h"
#import "CTEContentViewController.h"
#import "CTEMenuViewController.h"
#import "CTEChapterViewController.h"

@implementation CTEAppDelegate


//Set appropriate top-level view ctrlrs
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // create the content view controller that contains detail content
    CTEContentViewController *contentViewCtrlr = nil;
    
    // create the menuViewController so we can swap it in as the
    // windows root view controller whenever required
    CTEMenuViewController *menuViewCtrlr = nil;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        contentViewCtrlr = [[CTEChapterViewController alloc] initWithNibName:@"ChapteriPadView" bundle:nil];
        menuViewCtrlr = [[CTEMenuViewController alloc] initWithNibName:@"MenuiPadView" bundle:nil];
    }
    else {
        contentViewCtrlr = [[CTEChapterViewController alloc] initWithNibName:@"ChapteriPhoneView" bundle:nil];
        menuViewCtrlr = [[CTEMenuViewController alloc] initWithNibName:@"MenuiPhoneView" bundle:nil];
    }
    
    self.contentViewController = contentViewCtrlr;
    self.menuViewController = menuViewCtrlr;
    self.menuViewController.chapterData = [self getChapterData];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSideMenu)
                                                 name:ShowSideMenu
                                               object:nil];

    //init image cache
    self.imageCache = [NSMutableDictionary dictionary];
    
    //set the rootViewController to the contentViewController
    self.window.rootViewController = self.contentViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

//TODO these need to be moved to the framework

//Side menu actions
- (void)showSideMenu {
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
- (void)hideSideMenu:(CTESampleChapter *)selectedChapter {
    //TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //all animation takes place elsewhere. When this gets called just swap the contentViewController
    //if a new chapter is chosen, display that one
//    CTEChapterViewController *chapterViewController = (CTEChapterViewController *)self.contentViewController;
//    chapterViewController.currentChapter = selectedChapter;
    self.window.rootViewController = self.contentViewController;
}

//chapter data for menu
- (NSArray *)getChapterData {
    NSMutableArray *array = [NSMutableArray array];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Chapter4" ofType:@"txt"];
    NSString *chapterBody = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    CTESampleChapter *chapter = [[CTESampleChapter alloc] init];
    chapter.id = [NSNumber numberWithInt:4];
    chapter.title = @"Isle to Isle";
    chapter.subtitle = @"London & Dublin";
    chapter.body = chapterBody;
    [array addObject:chapter];
    NSLog(@"Created chapter: %@", chapter.title);
    
    path = [[NSBundle mainBundle] pathForResource:@"Chapter5" ofType:@"txt"];
    chapterBody = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    chapter = [[CTESampleChapter alloc] init];
    chapter.id = [NSNumber numberWithInt:5];
    chapter.title = @"Flanders to Funsterdam";
    chapter.subtitle = @"Bruges & Amsterdam";
    chapter.body = chapterBody;
    NSLog(@"Created chapter: %@", chapter.title);
    
    path = [[NSBundle mainBundle] pathForResource:@"Chapter6" ofType:@"txt"];
    chapterBody = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    chapter = [[CTESampleChapter alloc] init];
    chapter.id = [NSNumber numberWithInt:6];
    chapter.title = @"La Belle et le Bad Boy";
    chapter.subtitle = @"Paris & Nice";
    chapter.body = chapterBody;
    NSLog(@"Created chapter: %@", chapter.title);
    
    return array;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
