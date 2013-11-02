//
//  CTEMediaCache.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/2/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEMediaCache.h"

@implementation CTEMediaCache

@synthesize media;

+ (id)sharedMediaCache {
    static CTEMediaCache *sharedMediaCache = nil;
    @synchronized(self) {
        if (sharedMediaCache == nil)
            sharedMediaCache = [[self alloc] init];
    }
    return sharedMediaCache;
}

- (void)clearCache {
    [media removeAllObjects];
}

- (void)addImage:(UIImage *)image withKey:(NSString *)key {
    [media setValue:image forKey:key];
}

- (UIImage *)getImage:(NSString *)key {
    UIImage *image = (UIImage *)[media valueForKey:key];
    return image;
}

- (void)removeImage:(NSString *)key {
    [media removeObjectForKey:key];
}

- (id)init {
    if (self = [super init]) {
        media = [[NSMutableDictionary alloc] init];
    }
    return self;
}

@end
