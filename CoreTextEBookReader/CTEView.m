//
//  CTView.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEView.h"
#import "CTEMediaCache.h"
#import "CTEColumnView.h"

@interface CTEView() {
    int imagesLoaded;
}

@end

@implementation CTEView

NSString *const HTTP_PREFIX = @"http://";

@synthesize modalTarget;
@synthesize columns;
@synthesize attStrings;
@synthesize imageMetadatas;
@synthesize links;
@synthesize totalPages;

//sets text & image properties
- (void)setAttStrings:(NSDictionary *)allAttStrings
               images:(NSDictionary *)allImages
                links:(NSDictionary *)allLinks
                order:(NSArray *)allKeys {
    self.attStrings = allAttStrings;
    self.imageMetadatas = allImages;
    self.links = allLinks;
    self.orderedKeys = allKeys;
}

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
    
    CGMutablePathRef path = CGPathCreateMutable(); 
    CGRect textFrame = CGRectInset(self.bounds, frameXOffset, frameYOffset);
    CGPathAddRect(path, NULL, textFrame);
    
    //build for all chapters in order
    int columnIndex = 0;
    for(NSNumber *key in self.orderedKeys) {
        NSAttributedString *attString = (NSAttributedString *)[self.attStrings objectForKey:key];
        NSArray *chapImages = (NSArray *)[self.imageMetadatas objectForKey:key];
        NSArray *chapLinks = (NSArray *)[self.links objectForKey:key];
    
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attString);
        int textPos = 0;
        
        //check if column count isn't even; if not, means it's in mid-page and should create an empty column
        //this ensure chapters always begin on a new page
        float pageCount = ((float)columnIndex) / 2;
        float floorPageCount = floor(pageCount);
        if(pageCount != floorPageCount) {
            CGPoint colOffset = CGPointMake( (columnIndex + 1) * frameXOffset + columnIndex * (textFrame.size.width / pageColumnCount), 20 );
            CGRect colRect = CGRectMake(0, 0 , textFrame.size.width/pageColumnCount - columnWidthRightMargin, textFrame.size.height - 40);
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathAddRect(path, NULL, colRect);
            CTEColumnView *content = [[CTEColumnView alloc] initWithFrame: CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
            content.backgroundColor = [UIColor clearColor];
            content.frame = CGRectMake(colOffset.x, colOffset.y, colRect.size.width, colRect.size.height);
            [self.columns addObject:content];
            [self addSubview: content];
            columnIndex++;
        }
        
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
            content.attString = attString; //for link and image touches
            content.links = chapLinks;
            content.modalTarget = self.modalTarget;
            [self.columns addObject:content];
            
            //set the column view contents and add it as subview
            [content setCTFrame:(__bridge id)frameRef];
            [self addSubview: content];
                
            //see if any images exist in the column and load them in as well
            for(int imgIndex = 0; imgIndex < [chapImages count]; imgIndex++) {
                NSDictionary *imageInfo = [chapImages objectAtIndex:imgIndex];
                int imgLocation = [[imageInfo objectForKey:@"location"] intValue];
                
                //local versus online images
                NSString *imgFileName = [imageInfo objectForKey:@"fileName"];
                NSString *fileNamePrefix = [imgFileName substringToIndex:[HTTP_PREFIX length]];

                if(imgLocation >= textPos && imgLocation < textPos + frameRange.length) {
                    NSLog(@"imgFileName %@ exists in column between text post %d and %ld", imgFileName, textPos, (textPos + frameRange.length));
                    UIImage *img = nil;
                    
                    //remote image; load in async
                    if([fileNamePrefix isEqualToString:HTTP_PREFIX]) {
                        //placeholder image for now
                        NSNumber *imageWidth = [imageInfo objectForKey:@"width"];
                        NSNumber *imageHeight = [imageInfo objectForKey:@"height"];
                        
                        if([imageWidth floatValue] == 240.0f && [imageHeight floatValue] == 320.0f) {
                            img = [UIImage imageNamed:@"Placeholder240x320.jpg"];
                        }
                        else if([imageWidth floatValue] == 320.0 && [imageHeight floatValue] == 240.0f) {
                            img = [UIImage imageNamed:@"Placeholder320x240.jpg"];
                            
                        }
                        [self addImage:img forColumn:content frameRef:frameRef imageInfo:imageInfo];
                        
                        // download the image asynchronously
                        [self downloadImageWithURL:[NSURL URLWithString:imgFileName] completionBlock:^(BOOL succeeded, UIImage *image) {
                            if (succeeded) {
                                [self replaceImage:image forColumn:content imageInfo:imageInfo];
                            }
                        }];
                    }
                    else {
                        img = [UIImage imageNamed:imgFileName];
                        NSLog(@"LOCAL image %@ loaded in; updating column", imgFileName);
                        [self addImage:img forColumn:content frameRef:frameRef imageInfo:imageInfo];
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
    }
    
    
    //set the total width of the scroll view
    self.totalPages = (columnIndex+1) / pageColumnCount;
    self.contentSize = CGSizeMake(self.totalPages * self.bounds.size.width, textFrame.size.height);
    
    NSLog(@"CTView: END buildFrames");
}

//async image download
- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if ( !error )
                               {
                                   UIImage *image = [[UIImage alloc] initWithData:data];
                                   completionBlock(YES,image);
                               } else{
                                   completionBlock(NO,nil);
                               }
                           }];
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
                //Add image to the column view; metadata at index 2; img at index 0; TODO REPLACE WITH SOMETHING OBJECT-Y!!!
                NSMutableArray *imageData = [NSMutableArray arrayWithObjects:img, NSStringFromCGRect(imgBounds), imageInfo, nil];
                [col.imagesWithMetadata addObject:imageData];
            }
        }
        lineIndex++;
    }
}

//replaces image for specified matadata in specified column
- (void)replaceImage:(UIImage *)img forColumn:(CTEColumnView *)col imageInfo:(NSDictionary *)imageInfo {
    NSMutableArray *matchData = nil;
    for(NSMutableArray *imageData in col.imagesWithMetadata) {
        BOOL match = [imageInfo isEqualToDictionary:(NSDictionary *)[imageData objectAtIndex:2]];
        if(match) {
            matchData = imageData;
            break;
        }
    }
    
    if(matchData) {
        [matchData replaceObjectAtIndex:0 withObject:img];
        [col setNeedsDisplay];
    }
}

//Current page
- (int)getCurrentPage {
    CGFloat pageWidth = self.frame.size.width;
    return floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

@end
