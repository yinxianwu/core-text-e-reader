//
//  CTEMediaCache.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/2/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CTEMediaCache : NSObject

@property (nonatomic, strong) NSMutableDictionary *media;

+ (id)sharedMediaCache;
- (void)clearCache;
- (void)addImage:(UIImage *)image withKey:(NSString *)key;
- (UIImage *)getImage:(NSString *)key;
- (void)removeImage:(NSString *)key;

@end
