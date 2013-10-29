//
//  CTEChapter.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 10/28/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CTEChapter <NSObject>

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * body;

@end
