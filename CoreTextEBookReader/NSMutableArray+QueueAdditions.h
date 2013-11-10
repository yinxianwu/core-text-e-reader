//
//  NSMutableArray+QueueAdditions.h
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/9/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueAdditions)
- (id) dequeue;
- (void) enqueue:(id)obj;
@end