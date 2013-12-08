//
//  CTEAppDelegate.m
//  SampleApp
//
//  Created by David Jedeikin on 10/27/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTESampleChapter.h"
#import "CTEAppDelegate.h"

@implementation CTEAppDelegate

//Sample implementation of EBookReader
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UIColor *barTintColor = [UIColor colorWithRed:(225.0f/255.0f) green:(210.0f/255.0f) blue:(169.0f/255.0f) alpha:1.0f];
    UIColor *highlightColor = [UIColor colorWithRed:(75.0f/255.0f) green:(47.0/255.0f) blue:(29.0f/255.0f) alpha:1.0f];
    NSArray *chapters = [self getChapterData];
    self.delegate = [CTEDelegate delegateWithWindow:self.window
                                        andChapters:chapters
                                        andBarColor:barTintColor
                                  andHighlightColor:highlightColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

//chapter data for menu
- (NSArray *)getChapterData {
    NSMutableArray *array = [NSMutableArray array];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Chapter1" ofType:@"txt"];
    NSString *chapterBody = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    CTESampleChapter *chapter = [[CTESampleChapter alloc] init];
    chapter.id = [NSNumber numberWithInt:1];
    chapter.title = @"Origins";
    chapter.subtitle = @"Boston & San Francisco";
    chapter.body = chapterBody;
    [array addObject:chapter];
    NSLog(@"Created chapter: %@", chapter.title);
    
    path = [[NSBundle mainBundle] pathForResource:@"Chapter2" ofType:@"txt"];
    chapterBody = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    chapter = [[CTESampleChapter alloc] init];
    chapter.id = [NSNumber numberWithInt:2];
    chapter.title = @"Rocky Mountain High";
    chapter.subtitle = @"Denver";
    chapter.body = chapterBody;
    [array addObject:chapter];
    NSLog(@"Created chapter: %@", chapter.title);

    path = [[NSBundle mainBundle] pathForResource:@"Chapter3" ofType:@"txt"];
    chapterBody = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    chapter = [[CTESampleChapter alloc] init];
    chapter.id = [NSNumber numberWithInt:3];
    chapter.title = @"Motherland";
    chapter.subtitle = @"Montreal";
    chapter.body = chapterBody;
    [array addObject:chapter];
    NSLog(@"Created chapter: %@", chapter.title);
    
    path = [[NSBundle mainBundle] pathForResource:@"Chapter4" ofType:@"txt"];
    chapterBody = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    chapter = [[CTESampleChapter alloc] init];
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
    [array addObject:chapter];
    NSLog(@"Created chapter: %@", chapter.title);
    
    path = [[NSBundle mainBundle] pathForResource:@"Chapter6" ofType:@"txt"];
    chapterBody = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    chapter = [[CTESampleChapter alloc] init];
    chapter.id = [NSNumber numberWithInt:6];
    chapter.title = @"La Belle et le Bad Boy";
    chapter.subtitle = @"Paris & Nice";
    chapter.body = chapterBody;
    [array addObject:chapter];
    NSLog(@"Created chapter: %@", chapter.title);
    
    return array;
}

@end
