//
//  CTView.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEView.h"
#import "CTEColumnView.h"
#import "CTEConstants.h"
#import "CTEMarkupParser.h"
#import "FormatSelectionInfo.h"
#import "UIImage+Color.h"
#import <SDWebImage/SDWebImageManager.h>

@implementation CTEView

@synthesize viewDelegate;
@synthesize columns;
@synthesize orderedKeys;
@synthesize attStrings;
@synthesize imageMetadatas;
@synthesize links;
@synthesize orderedChapterPages;
@synthesize currentChapterID;
@synthesize totalPages;
@synthesize currentFont;
@synthesize currentFontSize;
@synthesize currentColumnCount;

//sets text & image properties
- (void)setAttStrings:(NSDictionary *)allAttStrings
               images:(NSDictionary *)allImages
                links:(NSDictionary *)allLinks
                order:(NSArray *)allKeys {
    self.attStrings = allAttStrings;
    self.imageMetadatas = allImages;
    self.links = allLinks;
    self.orderedKeys = allKeys;
    self.orderedChapterPages = [NSMutableArray arrayWithCapacity:self.orderedKeys.count];
}

//clears everything, including all caches
- (void)clearFrames {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    self.attStrings = nil;
    self.imageMetadatas = nil;
    self.links = nil;
    self.orderedKeys = nil;
    self.orderedChapterPages = [NSMutableArray array];
}

//builds all columns of text & images
- (void)buildFrames {
    NSLog(@"CTView: START buildFrames");
    
    //determine device type and size of text frame
    float columnWidthRightMargin;
    float columnWidthLeftMargin;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        frameYOffset = 20.0f;
        if(self.currentColumnCount == 2) {
            frameXOffset = 20.0f;
            columnWidthLeftMargin = 10.0f;
            columnWidthRightMargin = 10.0f;
        }
        else {
            frameXOffset = 0.0f;
            columnWidthLeftMargin = 0.0f;
            columnWidthRightMargin = 0.0f;
        }
    }
    else {
        frameXOffset = 0.0f;
        frameYOffset = 0.0f;
        columnWidthLeftMargin = 0.0f;
        columnWidthRightMargin = 20.0f;
    }
    
    [self setContentOffset:CGPointZero animated:NO]; //reset view to top
    self.pagingEnabled = YES;
    self.columns = [NSMutableArray array];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect scrollBounds = self.bounds;
    CGRect textFrame = CGRectInset(scrollBounds, frameXOffset, frameYOffset);
    CGPathAddRect(path, NULL, textFrame);
    
    //column sizing is standard across all columns
    CGFloat colRectWidth = [self columnWidthWithInset:columnWidthLeftMargin
                                               rightMargin:columnWidthRightMargin
                                                frameWidth:textFrame.size.width];
    CGFloat colRectHeight = textFrame.size.height - 40;
    [CTEMarkupParser setTextContainerWidth:colRectWidth];
    FormatSelectionInfo *info = [FormatSelectionInfo sharedInstance];
    BOOL shouldCachePageInfo = ![info hasPageInfoForFont:self.currentFont
                                                    size:self.currentFontSize
                                             columnCount:self.currentColumnCount];
    
    //build for all chapters in order
    int columnIndex = 0;
    int allChapsTextPos = 0;
    int pageTextStart = 0;
    int pageTextEnd = 0;
    float pageCount = ((float)columnIndex) / self.currentColumnCount;
    float floorPageCount = floorf(pageCount);
    float ceilPageCount = ceilf(pageCount);
    for(NSNumber *key in self.orderedKeys) {
        NSAttributedString *attString = (NSAttributedString *)[self.attStrings objectForKey:key];
        NSArray *chapImages = (NSArray *)[self.imageMetadatas objectForKey:key];
        NSArray *chapLinks = (NSArray *)[self.links objectForKey:key];
    
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attString);
        int textPos = 0;
        
        //check if column count isn't even; if not, means it's in mid-page and should create an empty column
        //this ensure chapters always begin on a new page
        if(pageCount != floorPageCount) {
            CGPoint colOffset = CGPointMake([self offsetXForColumn:columnIndex frameWidth:textFrame.size.width], 20);
            CGRect colRect = CGRectMake(0, 0, colRectWidth, colRectHeight);
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathAddRect(path, NULL, colRect);
            CTEColumnView *content = [[CTEColumnView alloc] initWithFrame: CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
            content.backgroundColor = [UIColor clearColor];
            content.frame = CGRectMake(colOffset.x, colOffset.y, colRectWidth, colRectHeight);
            [self.columns addObject:content];
            [self addSubview: content];
            columnIndex++;
            
            float prevPage = floorPageCount;
            pageCount = ((float)columnIndex) / self.currentColumnCount;
            floorPageCount = floorf(pageCount);
            ceilPageCount = ceilf(pageCount);
            
            //end of page reached, cache page info if not yet already cached
            pageTextEnd = allChapsTextPos;
            if(shouldCachePageInfo) {
                [info addPageInfo:[[NSNumber numberWithFloat:prevPage] intValue]
                        textStart:pageTextStart
                          textEnd:pageTextEnd
                             font:self.currentFont
                             size:self.currentFontSize
                      columnCount:self.currentColumnCount];
            }
        }
        //chapter always starts at the next page
        [self.orderedChapterPages addObject:[NSNumber numberWithFloat:ceilPageCount]];
        
        while (textPos < [attString length]) {
            //if page and floorPage are equal, it's the start of a new page
            if(pageCount == floorPageCount) {
                pageTextStart = allChapsTextPos;
            }
            NSLog(@"CTView: build CTColumnView %d at textPos %d", columnIndex, textPos);
            CGPoint colOffset = CGPointMake([self offsetXForColumn:columnIndex frameWidth:textFrame.size.width], 20);
            CGRect colRect = CGRectMake(0, 0, colRectWidth, colRectHeight);
            
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathAddRect(path, NULL, colRect);
            
            //use the column path
            CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, NULL);
            CFRange frameRange = CTFrameGetVisibleStringRange(frameRef);
            
            //create an empty column view
            CTEColumnView *columnView = [[CTEColumnView alloc] initWithFrame: CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
            columnView.backgroundColor = [UIColor clearColor];
            columnView.frame = CGRectMake(colOffset.x, colOffset.y, colRectWidth, colRectHeight);
            columnView.attString = attString; //for link and image touches
            columnView.links = chapLinks;
            columnView.viewDelegate = self.viewDelegate;
            [self.columns addObject:columnView];
            
            //set the column view contents and add it as subview
            [columnView setCTFrame:(__bridge id)frameRef];
            [self addSubview: columnView];
                
            //see if any images exist in the column and load them in as well
            for(int imgIndex = 0; imgIndex < [chapImages count]; imgIndex++) {
                NSDictionary *imageInfo = [chapImages objectAtIndex:imgIndex];
                int imgLocation = [[imageInfo objectForKey:@"location"] intValue];
                
                //local versus online images
                NSString *imgFileName = [imageInfo objectForKey:@"fileName"];
                NSString *fileNamePrefix = [imgFileName substringToIndex:[HttpPrefix length]];

                if(imgLocation >= textPos && imgLocation < textPos + frameRange.length) {
                    NSLog(@"imgFileName %@ exists in column between text post %d and %ld", imgFileName, textPos, (textPos + frameRange.length));
                    UIImage *img = nil;
                    
                    //remote image; load in async
                    if([fileNamePrefix isEqualToString:HttpPrefix]) {
                        //placeholder image -- fill with color
                        UIColor *color = [UIColor lightGrayColor];
                        img = [UIImage imageWithColor:color];
                        [columnView addImage:img imageInfo:imageInfo frameXOffset:frameXOffset frameYOffset:frameYOffset];
                        
                        //download the image asynchronously
                        SDWebImageManager *manager = [SDWebImageManager sharedManager];
                        [manager downloadWithURL:[NSURL URLWithString:imgFileName]
                                         options:0
                                        progress:^(NSUInteger receivedSize, long long expectedSize) { }
                                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                           if (image) {
                                               [columnView replaceImage:image imageInfo:imageInfo];
                                           }
                                       }];
                    }
                    else {
                        img = [UIImage imageNamed:imgFileName];
                        NSLog(@"LOCAL image %@ loaded in; updating column", imgFileName);
                        [columnView addImage:img imageInfo:imageInfo frameXOffset:frameXOffset frameYOffset:frameYOffset];
                    }
                }
            }
            
            //prepare for next frame
            columnView.textStart = allChapsTextPos;
            columnView.textEnd = allChapsTextPos + frameRange.length;
            textPos+= frameRange.length;
            allChapsTextPos+= frameRange.length;
            
            CFRelease(frameRef);
            CFRelease(path);
            
            columnIndex++;
            float prevPage = floorPageCount;
            pageCount = ((float)columnIndex) / self.currentColumnCount;
            floorPageCount = floorf(pageCount);
            ceilPageCount = ceilf(pageCount);
            
            //end of page reached, cache page info if not yet already cached
            if(floorPageCount > prevPage) {
                pageTextEnd = allChapsTextPos;
                FormatSelectionInfo *info = [FormatSelectionInfo sharedInstance];
                if(shouldCachePageInfo) {
                    [info addPageInfo:[[NSNumber numberWithFloat:prevPage] intValue]
                            textStart:pageTextStart
                              textEnd:pageTextEnd
                                 font:self.currentFont
                                 size:self.currentFontSize
                          columnCount:self.currentColumnCount];
                }
            }
        }
    }
    
    //set the total width of the scroll view
    self.totalPages = (columnIndex+1) / self.currentColumnCount;
    self.contentSize = CGSizeMake(self.totalPages * self.bounds.size.width, textFrame.size.height);
    
    //set current chapter to beginning
    self.currentChapterID = (NSNumber *)[self.orderedKeys objectAtIndex:0];
    
    NSLog(@"CTView: END buildFrames");
}

//Returns column width with specified laft & right margins
- (CGFloat)columnWidthWithInset:(float)leftMargin rightMargin:(float)rightMargin frameWidth:(CGFloat)frameWidth {
    CGFloat colWidth = (frameWidth / self.currentColumnCount) - leftMargin - rightMargin;
    //iPad adjustments
    if(self.currentColumnCount == 1 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        colWidth -= 50.0f;
    }
    return colWidth;
}

//Returns offset for specified frame column
- (CGFloat)offsetXForColumn:(int)columnIndex frameWidth:(CGFloat)frameWidth {
    CGFloat offsetX = (columnIndex + 1) * frameXOffset + columnIndex * (frameWidth / self.currentColumnCount);
    //iPad adjustments
    if(self.currentColumnCount == 1 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        offsetX += 20.0f;
    }
    return offsetX;
}

//Returns index of specified column
- (int)indexOfColumn:(id)column {
    int matchIndex = -1;
    int index = 0;
    for (CTEColumnView *columnView in self.columns) {
        if(columnView == column) {
            matchIndex = index;
            break;
        }
    }
    return matchIndex;
}

//respond to touch request, with either a page turn or utility bar toggle
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
    CGRect viewFrameInWindow = [self convertRect:self.bounds toView:nil];
    CGFloat endX = viewFrameInWindow.origin.x + viewFrameInWindow.size.width;
    CGPoint locationInWindow = [touch locationInView:nil];
    CGFloat pageTurnBoundary = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ?
                               PageTurnBoundaryPhone :
                               PageTurnBoundaryPad;
    
    //if it's anywhere within range of left or right edge, consider that a page turn request
    if(locationInWindow.x < pageTurnBoundary) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PageBackward object:self];
    }
    else if(locationInWindow.x > (endX - pageTurnBoundary)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PageForward object:self];
    }
    //otherwise, it's a utility bar toggle
    else {
        [viewDelegate toggleUtilityBars];
    }
}

//Current page, computed dynamically based on position
- (int)getCurrentPage {
    CGFloat pageWidth = self.frame.size.width;
    CGFloat currentPositionX = self.contentOffset.x;
    NSNumber *pageNbObj = [NSNumber numberWithDouble:floor(currentPositionX / pageWidth)];
    return [pageNbObj intValue];
}

//Convenience method
- (int)getCurrentTextPosition {
    return [self textStartForPage:[self getCurrentPage]];
}

//Returns attributed string start position for specified page
- (int)textStartForPage:(int)page {
    int textStart = -1;
    
    //get content offset for page
    CGFloat pageWidth = self.frame.size.width;
    CGFloat pageXOffsetStart = pageWidth * page;
    CGFloat pageXOffsetEnd = pageXOffsetStart + pageWidth;
    NSMutableArray *pageColumns = [NSMutableArray array];
    
    //add all subviews in the page
    for(UIView *subview in self.columns) {
        if(subview.frame.origin.x > pageXOffsetStart &&
           (subview.frame.origin.x + subview.frame.size.width) < pageXOffsetEnd) {
            [pageColumns addObject:subview];
        }
    }
    
    //only consider CTEColumnViews and find the one with the lowest textPosition
    for(CTEColumnView *pageColumn in pageColumns) {
        //init
        if(textStart == -1) {
            textStart = pageColumn.textStart;
        }
        //find smallest
        else if(pageColumn.textStart < textStart) {
            textStart = pageColumn.textStart;
        }
    }
    
    return textStart;
}

//Returns page number that contains specified text position
- (int)pageNumberForTextPosition:(int)position {
    int pageNb = -1;

    //find column that contains text position...
    CTEColumnView *matchColumn = nil;
    for(CTEColumnView *columnView in self.columns) {
        if(position >= columnView.textStart && position < columnView.textEnd) {
            matchColumn = columnView;
            break;
        }
    }
    
    //...then compute what page it's on
    if(matchColumn) {
        CGFloat pageWidth = self.frame.size.width;
        CGFloat columnXStart = matchColumn.frame.origin.x;
        NSNumber *pageNbObj = [NSNumber numberWithDouble:floor(columnXStart / pageWidth)];
        pageNb = [pageNbObj intValue];
    }
    return pageNb;
}

//Page number for selected chapter ID
- (NSNumber *)pageNumberForChapterID:(NSNumber *)chapterID {
    NSNumber *retVal = nil;
    for(int i = 0; i < [self.orderedKeys count]; i++) {
        NSNumber *matchChapterID = (NSNumber *)[self.orderedKeys objectAtIndex:i];
        if([matchChapterID isEqualToNumber:chapterID]) {
            retVal = (NSNumber *)[orderedChapterPages objectAtIndex:i];
            break;
        }
    }
    
    return retVal;
}

//Call to update current chapter (UI has changed)
- (void)currentChapterNeedsUpdate {
    int page = [self getCurrentPage];
    //need this check as -1 iteration will always be performed at least once otherwise
    if(self.orderedChapterPages.count > 0) {
        for(int i = 0; i < self.orderedChapterPages.count; i++) {
            NSNumber *pageNb = (NSNumber *)[self.orderedChapterPages objectAtIndex:i];
            
            //if it's the final chapter and no match found yet and page number is >
            //that chapter's start, then that chapter is "it"
            if(i+1 == self.orderedChapterPages.count && page >= [pageNb intValue]) {
                self.currentChapterID = (NSNumber *)[self.orderedKeys objectAtIndex:i];
                NSLog(@"SET currentChapterID: %@", self.currentChapterID);
                break;
            }
            else {
                NSNumber *nextPageNB = (NSNumber *)[self.orderedChapterPages objectAtIndex:i+1];
                if(page >= [pageNb intValue] && page < [nextPageNB intValue]) {
                    //grab current chapter ID from corresponding array
                    self.currentChapterID = (NSNumber *)[self.orderedKeys objectAtIndex:i];
                    NSLog(@"SET currentChapterID: %@", self.currentChapterID);
                    break;
                }
            }
        }
    }
}

//determines which columns to draw, based on position
- (void)setNeedsDisplay {
    CGPoint scrollOffset = self.contentOffset;
    NSArray *columnsToRender = [viewDelegate columnsToRenderBasedOnPosition:scrollOffset];
    if(columnsToRender) {
        for(UIView *subview in columnsToRender) {
            if([subview isKindOfClass:[CTEColumnView class]]) {
                CTEColumnView *column = (CTEColumnView *)subview;
                column.shouldDrawRect =YES;
            }
            [subview setNeedsDisplay];
        }
    }
    
    [super setNeedsDisplay];
}

@end
