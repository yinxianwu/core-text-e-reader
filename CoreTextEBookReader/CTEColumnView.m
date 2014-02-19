//
//  CTColumnView.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 4/14/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEColumnView.h"
#import "CTEUtils.h"
#import "CTEView.h"
#import "CTEConstants.h"
#import "CTEMarkupParser.h"
#import "UIImage+Color.h"

@implementation CTEColumnView

@synthesize viewDelegate;
@synthesize textStart;
@synthesize textEnd;
@synthesize imagesWithMetadata;
@synthesize links;
@synthesize attString;
@synthesize shouldDrawRect;

+(CTEColumnView *)columnWithDelegate:(id<CTEViewDelegate>)viewDelegate
                           attString:(NSAttributedString *)attString
                              images:(NSArray *)chapImages
                               links:(NSArray *)chapLinks
                                size:(CGSize)contentSize
                               frame:(CGRect)columnViewFrame
                         framesetter:(CTFramesetterRef)framesetter
                              insetX:(float)frameXInset
                              insetY:(float)frameYInset
                           colOffset:(CGPoint)colOffset
                         columnWidth:(CGFloat)columnWidth
                        columnHeight:(CGFloat)columnHeight
                        textPosition:(int)textPos
                absoluteTextPosition:(int)allChapsTextPos {
    CGRect colRect = CGRectMake(0, 0, columnViewFrame.size.width, columnViewFrame.size.height);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, colRect);
    
    //use the column path
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, NULL);
    CFRange frameRange = CTFrameGetVisibleStringRange(frameRef);
    
    //create an empty column view
    CTEColumnView *columnView = [[CTEColumnView alloc] initWithFrame:CGRectMake(0, 0, contentSize.width, contentSize.height)];
    columnView.backgroundColor = [UIColor clearColor];
    columnView.frame = CGRectMake(colOffset.x, colOffset.y, columnWidth, columnHeight);
    columnView.attString = attString; //for link and image touches
    columnView.links = chapLinks;
    columnView.viewDelegate = viewDelegate;
    
    //set the column view contents and add it as subview
    [columnView setCTFrame:(__bridge id)frameRef];
    
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
                [columnView addImage:img imageInfo:imageInfo frameXOffset:frameXInset frameYOffset:frameYInset];
                
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
                [columnView addImage:img imageInfo:imageInfo frameXOffset:frameXInset frameYOffset:frameYInset];
            }
        }
    }
    
    //prepare for next frame
    columnView.textStart = allChapsTextPos;
    columnView.textEnd = allChapsTextPos + frameRange.length;
    
    CFRelease(frameRef);
    CFRelease(path);
    
    return columnView;
}

//inits image array
-(id)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]!=nil) {
        self.imagesWithMetadata = [NSMutableArray array];
        self.links = [NSMutableArray array];
        self.shouldDrawRect = NO; //defaults to "don't draw" until otherwise instructed
    }
    return self;
}

//frame that column view will be drawn in
-(void)setCTFrame:(id)f {
    ctFrame = f;
}

//inserts image and associated info
- (void)addImage:(UIImage *)img
       imageInfo:(NSDictionary *)imageInfo
    frameXOffset:(float)frameXOffset
    frameYOffset:(float)frameYOffset {
    CTFrameRef frameRef = (__bridge CTFrameRef)ctFrame;
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
                
                CGFloat imgXOffset = -runBounds.origin.x; //left edge; column views will center in drawRect
                CGFloat imgYOffset = colRect.origin.y - frameYOffset - self.frame.origin.y;
                CGRect imgBounds = CGRectOffset(runBounds, imgXOffset, imgYOffset);
                //Add image to the column view; metadata at index 2; img at index 0; TODO REPLACE WITH SOMETHING OBJECT-Y!!!
                NSMutableArray *imageData = [NSMutableArray arrayWithObjects:img, NSStringFromCGRect(imgBounds), imageInfo, nil];
                [self.imagesWithMetadata addObject:imageData];
            }
        }
        lineIndex++;
    }
}

//Replaces image with specified info
//TODO this need to be made more memory-efficient by discarding images from the column cache once drawn
//all storage of images should come from the image cache
- (void)replaceImage:(UIImage *)img imageInfo:(NSDictionary *)imageInfo {
    NSMutableArray *matchData = nil;
    for(NSMutableArray *imageData in self.imagesWithMetadata) {
        NSDictionary *matchMetadata = (NSDictionary *)[imageData objectAtIndex:2];
        BOOL match = [imageInfo isEqualToDictionary:matchMetadata];
        
        //check clip file name, as movies are handled a bit differently
        if(!match) {
            NSString *clipFileName = [(NSString *)imageInfo valueForKey:@"clipFileName"];
            NSString *matchClipFileName = [(NSString *)matchMetadata valueForKey:@"clipFileName"];
            match = clipFileName != nil && matchClipFileName != nil && [matchClipFileName isEqualToString:clipFileName];
        }
        
        if(match) {
            matchData = imageData;
            break;
        }
    }
    
    if(matchData) {
        [matchData replaceObjectAtIndex:0 withObject:img];
        [self setNeedsDisplay];
    }
}

//End touch; determine location and if it's a link or image or other event
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //kick out if ctFrame is null -- means it's an empty column
    if(!ctFrame) {
        return;
    }
    
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	touchPoint.y += (18.0 / 1.3); //TODO font size now is set in parser
	CFArrayRef lines = CTFrameGetLines((__bridge CTFrameRef)(ctFrame));
	CGPoint origins[CFArrayGetCount(lines)];
	CTFrameGetLineOrigins((__bridge CTFrameRef)(ctFrame), CFRangeMake(0, 0), origins);
	CTLineRef line = NULL;
	CGPoint lineOrigin = CGPointZero;
	for (int i= 0; i < CFArrayGetCount(lines); i++) {
		CGPoint origin = origins[i];
		CGPathRef path = CTFrameGetPath((__bridge CTFrameRef)(ctFrame));
		CGRect rect = CGPathGetBoundingBox(path);
		CGFloat y = rect.origin.y + rect.size.height - origin.y;
        
		if ((touchPoint.y >= y) && (touchPoint.x >= origin.x)) {
			line = CFArrayGetValueAtIndex(lines, i);
			lineOrigin = origin;
		}
	}
	
	touchPoint.x -= lineOrigin.x;
	CFIndex index = CTLineGetStringIndexForPosition(line, touchPoint);
    
    //check to see if a link has been touched
    NSString *href = nil;
    for (NSDictionary *linkData in self.links) {
        NSNumber *linkLocation = [linkData objectForKey:@"location"];
        NSNumber *linkLength = [linkData objectForKey:@"length"];
        
        long linkLengthLong = [linkLength longValue];
        long linkLocationLong = [linkLocation longValue];
        
        //means link was tapped
        if(index >= linkLocationLong && index <= linkLocationLong + linkLengthLong) {
            href = [linkData objectForKey:@"href"];
            break;
        }
    }
    
    //check to see if an image or movie play button has been touched
    //check both line location and point location in case image is at top of screen and therefore out of line bounds
    NSString *movieClipPath = nil;
    UIImage *imageTouched = nil;
    NSDictionary *imageTouchedMetadata = nil;
    for (NSArray *imageData in self.imagesWithMetadata) {
        CGRect imageBounds = CGRectFromString([imageData objectAtIndex:1]);
        NSDictionary *imageMetadata = [imageData objectAtIndex:2];
        int imageLineLocation = [[imageMetadata objectForKey:@"location"] intValue];
        
        //+-2 lines from image means it was touched
        long indexMin = index - 2;
        long indexMax = index + 2;
        BOOL imageTouchedByLine = imageLineLocation >= indexMin && imageLineLocation <= indexMax;
        
        //within bounds of image means it was touched
        //may need to adjust if image bounds claim it's beyond column bounds end
        CGRect columnBounds = self.bounds;
        CGFloat imageEndY = imageBounds.origin.y + imageBounds.size.height;
        CGFloat imageOriginY = imageEndY >= columnBounds.size.height ? 0 : imageBounds.origin.y;
        BOOL imageTouchedByPoint = touchPoint.x > imageBounds.origin.x &&
                                   touchPoint.x < (imageBounds.origin.x + imageBounds.size.width) &&
                                   touchPoint.y > imageOriginY &&
                                   touchPoint.y < (imageOriginY + imageBounds.size.height);
        if(imageTouchedByLine || imageTouchedByPoint) {
            imageTouchedMetadata = imageMetadata;
            imageTouched = (UIImage *)[imageData objectAtIndex:0];
            break;
        }
        //check to see if a play button has been touched
        if([imageMetadata objectForKey:@"playButtonLocation"] && [imageMetadata objectForKey:@"clipFileName"]) {
            NSString *clipPath = [imageMetadata objectForKey:@"clipFileName"];
            CGRect matchRect = [[imageMetadata objectForKey:@"playButtonLocation"] CGRectValue];
            if(touchPoint.x > matchRect.origin.x && touchPoint.x < matchRect.origin.x + matchRect.size.width &&
               touchPoint.y > matchRect.origin.y && touchPoint.y < matchRect.origin.y + matchRect.size.height) {
                NSLog(@"play button touched for movie %@", clipPath);
                movieClipPath = clipPath;
                break;
            }
        }
    }
    
    //if link, open URL in Safari
    if(href != nil) {
        NSURL *url = [NSURL URLWithString:href];
        [[UIApplication sharedApplication] openURL:url];
    }
    //if movie, pass off to delegate
    else if(movieClipPath != nil&& self.viewDelegate != nil) {
        [viewDelegate playMovie:movieClipPath];
    }
    //open image or clip in new view
    //check if it's a movie-type preview image
    else if(imageTouched != nil && imageTouchedMetadata != nil && self.viewDelegate != nil) {
        NSString *imagePath = (NSString *)[imageTouchedMetadata objectForKey:@"fileName"];
        NSString *clipPath = (NSString *)[imageTouchedMetadata objectForKey:@"clipFileName"];
        
        //kick out if it's a local image
        //TODO better way of doing this...
        if(![imagePath isEqualToString:@"SectionDivider169Black.png"]) {
            //image vs movie clip
            if(clipPath) {
                [viewDelegate playMovie:clipPath];
            }
            else {
                [viewDelegate showImage:imageTouched];
            }
        }
    }
    //toggle toolbars or flip pages, depending on location
    else if(self.viewDelegate != nil) {
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
}

//drawing method
- (void)drawRect:(CGRect)rect {
    if(![self shouldDrawRect]) {
        return;
    }
    
    NSLog(@"CTColumnView: START drawRect; frame: %f", self.frame.origin.x);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Flip the coordinate system
    CGFloat columnHeight = self.bounds.size.height;
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, columnHeight);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    //draw text
    CTFrameDraw((__bridge CTFrameRef)ctFrame, context);
    
    //draw images using size created in markup parser
    int imageIndex = 0;
    for (NSArray *imageData in self.imagesWithMetadata) {
        UIImage *img = [imageData objectAtIndex:0];
        NSDictionary *imgMetadata = [imageData objectAtIndex:2];
        CGRect imgBounds = CGRectFromString([imageData objectAtIndex:1]);
        
        //center all images in column
        CGFloat imgXOffset = (self.bounds.size.width - imgBounds.size.width) / 2;
        CGContextTranslateCTM(context, imgXOffset, 0);
        CGContextDrawImage(context, imgBounds, img.CGImage);
        
        //play button for movie previews
        if([imgMetadata valueForKey:@"playButtonImage"]) {
            NSLog(@"Draw PLAY BUTTON for %@", [imgMetadata valueForKey:@"fileName"]);
            UIImage *playButtonImage = [imgMetadata valueForKey:@"playButtonImage"];
            CGFloat previewImageHeight = imgBounds.size.height;
            CGFloat previewImageWidth = imgBounds.size.width;
            CGFloat playButtonHeight = playButtonImage.size.height;
            CGFloat playButtonWidth = playButtonImage.size.width;
            CGFloat playButtonOriginX = (previewImageWidth / 2) - 30; //scaled width
            CGFloat playButtonOriginY = (previewImageHeight / 2) - 30; //scaled height
            CGRect playButtonBounds = CGRectFromString(@"{{0, 0}, {60, 60}}");

            CGContextTranslateCTM(context,
                                  playButtonOriginX,
                                  imgBounds.origin.y + playButtonOriginY);
            CGContextDrawImage(context, playButtonBounds, playButtonImage.CGImage);
            //add location to cache
            CGRect playButtonLocation = CGRectMake(playButtonOriginX, playButtonOriginY, playButtonWidth, playButtonHeight);
            NSMutableDictionary *newImageMetadata = [NSMutableDictionary dictionaryWithDictionary:imgMetadata];
            [newImageMetadata setValue:[NSValue valueWithCGRect:playButtonLocation] forKey:@"playButtonLocation"];
            NSMutableArray *newImageData = [NSMutableArray arrayWithArray:imageData];
            [newImageData replaceObjectAtIndex:2 withObject:newImageMetadata];
            [self.imagesWithMetadata replaceObjectAtIndex:imageIndex withObject:newImageData];
        }
             
        imageIndex++;
    }

    //add to the delegate's count of columns rendered
    [viewDelegate.columnsRendered addObject:self];
    NSLog(@"CTColumnView: END drawRect");
}

@end