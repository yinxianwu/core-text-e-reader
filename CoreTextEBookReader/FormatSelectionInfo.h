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

- (void)addPageInfo:(int)pageNb
          textStart:(int)pageTextStart
            textEnd:(int)pageTextEnd
               font:(NSString *)font
               size:(float)size
        columnCount:(int)colCount;

- (BOOL)hasPageInfoForFont:(NSString *)font
                      size:(float)size
               columnCount:(int)colCount;

- (NSArray *)getPageForLocation:(int)location
                           font:(NSString *)font
                           size:(float)size
                    columnCount:(int)colCount;

@end
