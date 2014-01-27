//
//  FormatSelectionPageInfo.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 1/25/14.
//  Copyright (c) 2014 com.davidjed. All rights reserved.
//

#import "FormatSelectionInfo.h"

//private container class for single page
@interface __PageInfo : NSObject
@property (nonatomic) int page;
@property (nonatomic) int textStart;
@property (nonatomic) int textEnd;
@end

@implementation __PageInfo
@synthesize page;
@synthesize textStart;
@synthesize textEnd;

- (id)initWithPage:(int)pageNb
         textStart:(int)pageTextStart
           textEnd:(int)pageTextEnd {
    self = [super init];
    if(self) {
        self.page = pageNb;
        self.textStart = pageTextStart;
        self.textEnd = pageTextEnd;
    }

    return self;
}
@end

@implementation FormatSelectionInfo {
    NSMutableDictionary *_allPageInfo;
}

//singleton impl
+ (id)sharedInstance {
    static FormatSelectionInfo *sharedFSPI = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFSPI = [[self alloc] init];
    });
    return sharedFSPI;
}

- (id)init {
    self = [super init];
    if(self) {
        _allPageInfo = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)addPageInfo:(int)pageNb
          textStart:(int)pageTextStart
            textEnd:(int)pageTextEnd
               font:(NSString *)font
               size:(float)size
        columnCount:(int)colCount {
    NSMutableArray *pageInfoForKey = nil;
    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
    
    pageInfoForKey = (NSMutableArray *)[_allPageInfo objectForKey:key];
    
    if(!pageInfoForKey) {
        pageInfoForKey = [NSMutableArray array];
        [_allPageInfo setObject:pageInfoForKey forKey:key];
    }
    __PageInfo *pageInfo = [[__PageInfo alloc] initWithPage:pageNb textStart:pageTextStart textEnd:pageTextEnd];
    [pageInfoForKey addObject:pageInfo];
    
}

- (BOOL)hasPageInfoForFont:(NSString *)font
                      size:(float)size
               columnCount:(int)colCount {
    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
    return [_allPageInfo objectForKey:key] != nil;
}

- (NSArray *)getPageForLocation:(int)location
                           font:(NSString *)font
                           size:(float)size
                    columnCount:(int)colCount {
    //TODO
    return nil;
}

//key is String concatenation of font-size-column combo, which is
//guaranteed to be unique as all font names are distinctive
- (NSString *)keyFromFont:(NSString *)font
                     size:(float)size
              columnCount:(int)colCount {
    NSString *key = [NSString stringWithFormat:@"%@|%f|%d", font, size, colCount];
    return key;
}

@end
