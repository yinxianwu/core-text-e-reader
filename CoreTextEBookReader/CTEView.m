//
//  CTView.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "CTEView.h"

@interface CTEView() {
    int imagesLoaded;
}

@end

@implementation CTEView

@synthesize modalTarget;
@synthesize attString;
@synthesize columns;
@synthesize columnsRendered;
@synthesize imageMetadatas;
@synthesize links;
@synthesize totalPages;

//builds all columns of text & images
- (void)buildFrames {
    NSLog(@"CTView: START buildFrames");
    
    //determine device type and size of text frame
    float columnWidthRightMargin;
    int pageColumnCount;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        frameXOffset = 20;
        frameYOffset = 20;
        columnWidthRightMargin = frameYOffset;
        pageColumnCount = 2;
    }
    else {
        frameXOffset = 0;
        frameYOffset = 0;
        columnWidthRightMargin = 20;
        pageColumnCount = 1;
    }
    
    [self setContentOffset:CGPointZero animated:NO]; //reset view to top
    self.pagingEnabled = YES;
    self.columns = [NSMutableArray array];
    self.columnsRendered = [NSMutableArray array];
    
    CGMutablePathRef path = CGPathCreateMutable(); 
    CGRect textFrame = CGRectInset(self.bounds, frameXOffset, frameYOffset);
    CGPathAddRect(path, NULL, textFrame);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attString);
    int textPos = 0;
    int columnIndex = 0;
    
    while (textPos < [attString length]) { 
        NSLog(@"CTView: build CTColumnView %d at textPos %d", columnIndex, textPos);
        
        CGPoint colOffset = CGPointMake( (columnIndex + 1) * frameXOffset + columnIndex * (textFrame.size.width / pageColumnCount), 20 );
        CGRect colRect = CGRectMake(0, 0 , textFrame.size.width/pageColumnCount - columnWidthRightMargin, textFrame.size.height - 40);
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, colRect);
        
        //use the column path
        CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, NULL);
        CFRange frameRange = CTFrameGetVisibleStringRange(frameRef); 
        
        //create an empty column view
        CTEColumnView *content = [[CTEColumnView alloc] initWithFrame: CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
        content.backgroundColor = [UIColor clearColor];
        content.frame = CGRectMake(colOffset.x, colOffset.y, colRect.size.width, colRect.size.height);
        content.attString = self.attString; //for link and image touches
        content.links = self.links;
        content.modalTarget = self.modalTarget;
        [self.columns addObject:content];
        [self.columnsRendered addObject:[NSNumber numberWithBool:NO]]; //mark as unrendered
        
		//set the column view contents and add it as subview
        [content setCTFrame:(__bridge id)frameRef];  
        [self addSubview: content];
        
        //see if any images exist in the column and load them in as well
        dispatch_queue_t main = dispatch_get_main_queue();
        for(int imgIndex = 0; imgIndex < [self.imageMetadatas count]; imgIndex++) {
            NSDictionary *imageInfo = [self.imageMetadatas objectAtIndex:imgIndex];
            int imgLocation = [[imageInfo objectForKey:@"location"] intValue];
            
            //local versus online images
            NSString *imgFileName = [imageInfo objectForKey:@"fileName"];
            NSString *fileNamePrefix = [imgFileName substringToIndex:7];
            
            if(imgLocation >= textPos && imgLocation < textPos + frameRange.length) {
                NSLog(@"imgFileName %@ exists in column between text post %d and %ld", imgFileName, textPos, (textPos + frameRange.length));
                UIImage *img = nil;
                
                //remote image; load in async
                //TODO this ain't pretty but it works...
                if([fileNamePrefix isEqualToString:@"http://"]) {
                    //remote images are unique per chapter, so if it's in the cache can reuse it
                    //TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//                    img = [app_delegate.imageCache valueForKey:imgFileName];
                    if(!img) {
                        NSLog(@"Image %@ doesn't exist; loading it in...", imgFileName);
                        dispatch_queue_t queue = dispatch_queue_create([imgFileName UTF8String], NULL);
                        dispatch_async(queue, ^{
                            NSURL *url = [NSURL URLWithString:imgFileName];
                            NSData *data = [NSData dataWithContentsOfURL:url];
                            UIImage *imgLoaded = [UIImage imageWithData:data];
                            
                            //error handling
                            if (!imgLoaded) {
                                imgLoaded = [UIImage imageNamed:@"ImageError.png"];
                            }
                            
                            //update image load count on main thread
                            dispatch_async(main, ^{
                                NSLog(@"Image %@ loaded in; updating column", imgFileName);
                                //TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//                                [app_delegate.imageCache setValue:imgLoaded forKey:imgFileName];
                                [self addImage:imgLoaded forColumn:content frameRef:frameRef imageInfo:imageInfo];
                                [content setNeedsDisplay];
                            });
                        });
                    }
                    else {
                        NSLog(@"Image %@ cached; updating column", imgFileName);
                        [self addImage:img forColumn:content frameRef:frameRef imageInfo:imageInfo];
                        [content setNeedsDisplay];
                    }
                }
                else {
                    img = [UIImage imageNamed:imgFileName];
                    NSLog(@"LOCAL image %@ loaded in; updating column", imgFileName);
                    [self addImage:img forColumn:content frameRef:frameRef imageInfo:imageInfo];
                    [content setNeedsDisplay];
                }
            }
        }
        
        //prepare for next frame
        content.textStart = textPos;
        content.textEnd = textPos + frameRange.length;
        textPos+= frameRange.length;
        
        CFRelease(frameRef);
        CFRelease(path);
        
        columnIndex++;
    }
    
    //set the total width of the scroll view
    self.totalPages = (columnIndex+1) / pageColumnCount;
    self.contentSize = CGSizeMake(self.totalPages * self.bounds.size.width, textFrame.size.height);
    
    NSLog(@"CTView: END buildFrames");
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

//clears all columns of text & images
//also clears app image cache for memory reasons
- (void)clearFrames {
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    [self.columns removeAllObjects];
    [self.columnsRendered removeAllObjects];
    [self.imageMetadatas removeAllObjects];
    [self.links removeAllObjects];
    //TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//    [app_delegate.imageCache removeAllObjects];
}

//force a column refresh
//only redraw columns that haven't been drawn yet and are one before or after the current column's page
- (void)redrawFrames {
    NSLog(@"CTView: START redrawFrames");
    int index = 0;
    for (CTEColumnView *columnView in self.columns) {
        BOOL wasPageRendered = [[self.columnsRendered objectAtIndex:index] boolValue];
        BOOL shouldRender = [columnView shouldDrawRect:[columnView bounds]];
        if(shouldRender && !wasPageRendered) {
            NSLog(@"column at index %d needs display", index);
            [columnView setNeedsDisplay];
            [self.columnsRendered replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:YES]];
        }
        index++;
    }
    NSLog(@"CTView: END redrawFrames");
}

//sets text & image properties, and kicks off image load
- (void)setAttString:(NSAttributedString *)string withImages:(NSArray*)imgs andLinks:(NSArray*)lnks {
    self.attString = string;
    self.imageMetadatas = [NSMutableArray arrayWithArray:imgs];
    self.links = [NSMutableArray arrayWithArray:lnks];
}

//inserts image and associated info into correct CTColumnView
- (void)addImage:(UIImage *)img forColumn:(CTEColumnView *)col frameRef:(CTFrameRef)frameRef imageInfo:(NSDictionary *)imageInfo {
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frameRef);
    CGPoint origins[[lines count]];
    CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), origins);
    NSUInteger lineIndex = 0;
    int imgLocation = [[imageInfo objectForKey:@"location"] intValue];
    for (id lineObj in lines) {
        CTLineRef line = (__bridge CTLineRef)lineObj;
        
        for (id runObj in (__bridge NSArray *)CTLineGetGlyphRuns(line)) {
            CTRunRef run = (__bridge CTRunRef)runObj;
            CFRange runRange = CTRunGetStringRange(run);
            
            if (runRange.location <= imgLocation && runRange.location+runRange.length > imgLocation) {
                CGRect runBounds;
                CGFloat ascent;//height above the baseline
                CGFloat descent;//height below the baseline
                runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
                runBounds.size.height = ascent + descent;
                
                CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
                runBounds.origin.x = origins[lineIndex].x + self.frame.origin.x + xOffset + frameXOffset;
                runBounds.origin.y = origins[lineIndex].y + self.frame.origin.y + frameYOffset;
                runBounds.origin.y -= descent;
                
                //set image properties and add to view
                CGPathRef pathRef = CTFrameGetPath(frameRef);
                CGRect colRect = CGPathGetBoundingBox(pathRef);
                
                CGRect imgBounds = CGRectOffset(runBounds,
                                                colRect.origin.x - frameXOffset - self.contentOffset.x,
                                                colRect.origin.y - frameYOffset - self.frame.origin.y);
                //Add image to the column view; metadata at index 2
                NSArray *imageData = [NSArray arrayWithObjects:img, NSStringFromCGRect(imgBounds), imageInfo, nil];
                [col.images addObject:imageData];
            }
        }
        lineIndex++;
    }
}

//Current page
- (int)getCurrentPage {
    CGFloat pageWidth = self.frame.size.width;
    return floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

@end
