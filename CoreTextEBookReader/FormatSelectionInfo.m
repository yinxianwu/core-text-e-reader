//
//  FormatSelectionPageInfo.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 1/25/14.
//  Copyright (c) 2014 com.davidjed. All rights reserved.
//

#import "FormatSelectionInfo.h"

//private container class for single formatselection
//@interface __SingleFormatSelectionInfo : NSObject
//@property NSDictionary *attStrings;
//@property NSDictionary *imageInfo;
//@property NSDictionary *linkInfo;
//@property NSArray *pageInfo;
//@end
//
//@implementation __SingleFormatSelectionInfo
//@synthesize attStrings;
//@synthesize imageInfo;
//@synthesize linkInfo;
////- (id)init {
////    self = [super init];
////    if(self) {
////        self.attStrings = [NSMutableDictionary dictionary];
////        self.imageInfo = [NSMutableDictionary dictionary];
////        self.linkInfo = [NSMutableDictionary dictionary];
////    }
////    
////    return self;
////}
//@end

@interface FormatSelectionInfo()

//contains all format selections
@property NSMutableDictionary *info;

@end

@implementation FormatSelectionInfo

@synthesize info;

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
        info = [NSMutableDictionary dictionary];
    }
    
    return self;
}

//- (void)addAttStrings:(NSDictionary *)attStrings
//            imageInfo:(NSDictionary *)imageInfo
//             linkInfo:(NSDictionary *)linkInfo
//                 font:(NSString *)font
//                 size:(float)size
//          columnCount:(int)colCount {
//    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
//    __SingleFormatSelectionInfo *selectionInfo = (__SingleFormatSelectionInfo *)[info objectForKey:key];
//    if(selectionInfo == nil) {
//        selectionInfo = [[__SingleFormatSelectionInfo alloc] init];
//        [info setObject:selectionInfo forKey:key];
//    }
//    selectionInfo.attStrings = attStrings;
//    selectionInfo.imageInfo = imageInfo;
//    selectionInfo.linkInfo = linkInfo;
//}

- (void)addPageInfo:(NSArray *)pageInfo
               font:(NSString *)font
               size:(float)size
        columnCount:(int)colCount {
//    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
//    __SingleFormatSelectionInfo *selectionInfo = (__SingleFormatSelectionInfo *)[info objectForKey:key];
//    if(selectionInfo == nil) {
//        selectionInfo = [[__SingleFormatSelectionInfo alloc] init];
//        [info setObject:selectionInfo forKey:key];
//    }
//
//    selectionInfo.pageInfo = pageInfo;
}

- (BOOL)hasPageInfoForFont:(NSString *)font
                      size:(float)size
               columnCount:(int)colCount {
//    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
//    __SingleFormatSelectionInfo *selectionInfo = (__SingleFormatSelectionInfo *)[info objectForKey:key];
//    if(selectionInfo == nil) {
//        return NO;
//    }
//    else if(selectionInfo.pageInfo) {
//        return YES;
//    }
//    else {
        return NO;
//    }
}

- (NSArray *)getPageInfoForFont:(NSString *)font
                           size:(float)size
                    columnCount:(int)colCount {
//    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
//    __SingleFormatSelectionInfo *selectionInfo = (__SingleFormatSelectionInfo *)[info objectForKey:key];
//    if(selectionInfo == nil) {
        return nil;
//    }
//    else {
//        return selectionInfo.pageInfo;
//    }
}

//- (BOOL)hasAttStringsForFont:(NSString *)font
//                        size:(float)size
//                 columnCount:(int)colCount {
//    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
//    __SingleFormatSelectionInfo *selectionInfo = (__SingleFormatSelectionInfo *)[info objectForKey:key];
//    if(selectionInfo == nil) {
//        return NO;
//    }
//    else if(selectionInfo.attStrings) {
//        return YES;
//    }
//    else {
//        return NO;
//    }
//}

//- (NSDictionary *)getAttStringsForFont:(NSString *)font
//                                  size:(float)size
//                           columnCount:(int)colCount {
//    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
//    __SingleFormatSelectionInfo *selectionInfo = (__SingleFormatSelectionInfo *)[info objectForKey:key];
//    if(selectionInfo == nil) {
//        return nil;
//    }
//    else {
//        return selectionInfo.attStrings;
//    }
//}

//- (NSDictionary *)getImageInfoForFont:(NSString *)font
//                                 size:(float)size
//                          columnCount:(int)colCount {
//    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
//    __SingleFormatSelectionInfo *selectionInfo = (__SingleFormatSelectionInfo *)[info objectForKey:key];
//    if(selectionInfo == nil) {
//        return nil;
//    }
//    else {
//        return selectionInfo.imageInfo;
//    }
//}

//- (NSDictionary *)getLinkInfoForFont:(NSString *)font
//                                size:(float)size
//                         columnCount:(int)colCount {
//    NSString *key = [self keyFromFont:font size:size columnCount:colCount];
//    __SingleFormatSelectionInfo *selectionInfo = (__SingleFormatSelectionInfo *)[info objectForKey:key];
//    if(selectionInfo == nil) {
//        return nil;
//    }
//    else {
//        return selectionInfo.linkInfo;
//    }
//}

- (NSArray *)getPageForLocation:(int)location
                           font:(NSString *)font
                           size:(float)size
                    columnCount:(int)colCount {
    //TODO
    return nil;
}

//key is String concatenation of font-size-column combo, which is guaranteed to be unique as all
//font names are distinctive
- (NSString *)keyFromFont:(NSString *)font
                     size:(float)size
              columnCount:(int)colCount {
    NSString *key = [NSString stringWithFormat:@"%@|%f|%d", font, size, colCount];
    return key;
}

@end
