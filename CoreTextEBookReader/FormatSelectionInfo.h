//
//  FormatSelectionPageInfo.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 1/25/14.
//  Copyright (c) 2014 com.davidjed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FormatSelectionInfo : NSObject

+ (id)sharedInstance;

//- (void)addAttStrings:(NSDictionary *)attStrings
//            imageInfo:(NSDictionary *)imageInfo
//             linkInfo:(NSDictionary *)linkInfo
//                 font:(NSString *)font
//                 size:(float)size
//          columnCount:(int)colCount;

- (void)addPageInfo:(NSArray *)pageInfo
               font:(NSString *)font
               size:(float)size
        columnCount:(int)colCount;

- (BOOL)hasPageInfoForFont:(NSString *)font
                      size:(float)size
               columnCount:(int)colCount;

- (NSArray *)getPageInfoForFont:(NSString *)font
                           size:(float)size
                    columnCount:(int)colCount;

//- (BOOL)hasAttStringsForFont:(NSString *)font
//                        size:(float)size
//                 columnCount:(int)colCount;
//
//- (NSDictionary *)getAttStringsForFont:(NSString *)font
//                                  size:(float)size
//                           columnCount:(int)colCount;
//
//- (NSDictionary *)getImageInfoForFont:(NSString *)font
//                                 size:(float)size
//                          columnCount:(int)colCount;
//
//- (NSDictionary *)getLinkInfoForFont:(NSString *)font
//                                size:(float)size
//                         columnCount:(int)colCount;

- (NSArray *)getPageForLocation:(int)location
                           font:(NSString *)font
                           size:(float)size
                    columnCount:(int)colCount;

@end
