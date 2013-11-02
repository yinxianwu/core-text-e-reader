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

    NSArray *chapters = [self getChapterData];
    self.delegate = [CTEDelegate delegateWithWindow:self.window andChapters:chapters];
    [self.window makeKeyAndVisible];
    
    return YES;
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
