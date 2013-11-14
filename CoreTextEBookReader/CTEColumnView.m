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

@interface CTEColumnView()
@property NSArray *spinnerViews;
@end

@implementation CTEColumnView

@synthesize textStart;
@synthesize textEnd;
@synthesize imagesWithMetadata;
@synthesize links;
@synthesize attString;
@synthesize modalTarget;
@synthesize player;
@synthesize spinnerViews;


//inits image array
-(id)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]!=nil) {
        self.imagesWithMetadata = [NSMutableArray array];
        self.links = [NSMutableArray array];
    }
    return self;
}

//frame that column view will be drawn in
-(void)setCTFrame: (id) f {
    ctFrame = f;
}

//Begin touch; determine location and if it's a link or image
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //kick out if ctFrame is null -- means it's an empty column
    if(!ctFrame) {
        return;
    }
    
	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	location.y += (18.0 / 1.3); //TODO font size now is set in parser

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
        
		if ((location.y >= y) && (location.x >= origin.x))
		{
			line = CFArrayGetValueAtIndex(lines, i);
			lineOrigin = origin;
		}
	}
	
	location.x -= lineOrigin.x;
	CFIndex index = CTLineGetStringIndexForPosition(line, location);
    
    //check to see if a link has been touched
    NSString *href = nil;
    for (NSDictionary *linkData in self.links) {
        NSNumber *linkLocation = [linkData objectForKey:@"location"];
        NSNumber *linkLength = [linkData objectForKey:@"length"];
        
        long length = [linkLength longValue];
        long location = [linkLocation longValue];
        
        //means link was tapped
        if(index >= location && index <= location + length) {
            href = [linkData objectForKey:@"href"];
            break;
        }
    }
    
    //check to see if an image or movie play button has been touched
    NSString *movieClipPath = nil;
    NSDictionary *imageTouched = nil;
    for (NSArray *imageData in self.imagesWithMetadata) {
        NSDictionary *imageMetadata = [imageData objectAtIndex:2];
        int imgLocation = [[imageMetadata objectForKey:@"location"] intValue];
        
        //means image was touched
        long indexMin = index - 3;
        long indexMax = index + 3;
        if(imgLocation >= indexMin && imgLocation <= indexMax) {
            imageTouched = imageMetadata;
            break;
        }
        //check to see if a play button has been touched
        if([imageMetadata objectForKey:@"playButtonLocation"] && [imageMetadata objectForKey:@"clipFileName"]) {
            NSString *clipPath = [imageMetadata objectForKey:@"clipFileName"];
            CGRect matchRect = [[imageMetadata objectForKey:@"playButtonLocation"] CGRectValue];
            if(location.x > matchRect.origin.x && location.x < matchRect.origin.x + matchRect.size.width &&
               location.y > matchRect.origin.y && location.y < matchRect.origin.y + matchRect.size.height) {
                NSLog(@"play button touched for movie %@", clipPath);
                movieClipPath = clipPath;
                break;
            }
        }
    }
    
    //open URL in Safari
    if(href != nil) {
        NSURL *url = [NSURL URLWithString:href];
        [[UIApplication sharedApplication] openURL:url];
    }
    else if(movieClipPath != nil) {
        [self playMovie:movieClipPath];
    }
    //open image or clip in new view
    //check if it's a movie-type preview image
    else if(imageTouched != nil && modalTarget != nil) {
        NSString *imagePath = (NSString *)[imageTouched objectForKey:@"fileName"];
        NSString *clipPath = (NSString *)[imageTouched objectForKey:@"clipFileName"];
        
        //kick out if it's a local image
        //TODO better way of doing this...
        if(![imagePath isEqualToString:@"SectionDivider169Black.png"]) {
            //image vs movie clip
            if(clipPath) {
                [self playMovie:clipPath];
            }
            else {
                CTEImageViewController *imageView;
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                    imageView = [[CTEImageViewController alloc]initWithNibName:@"ImageiPhoneView" bundle:nil imagePath:imagePath];
                }
                else {
                    imageView = [[CTEImageViewController alloc]initWithNibName:@"ImageiPadView" bundle:nil imagePath:imagePath];
                }
                [modalTarget presentViewController:imageView animated:YES completion:nil];
            }
        }
    }
}

//plays specified movie at path
- (void)playMovie:(NSString *)clipPath {
    self.spinnerViews = [CTEUtils startSpinnerOnView:self.modalTarget.view];
    self.player = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:clipPath]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateChanged:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [self.player.moviePlayer prepareToPlay];
}

//listens for state changes in movie load
- (void)moviePlayerLoadStateChanged:(NSNotification *)notification {
    NSLog(@"moviePlayerLoadStateChanged");
    MPMovieLoadState loadState = self.player.moviePlayer.loadState;
    if(loadState == MPMovieLoadStatePlayable) {
        NSLog(@"MPMovieLoadStatePlaythroughOK; loading player...");
        [CTEUtils stopSpinnerOnView:self.modalTarget.view withSpinner:self.spinnerViews];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
        [modalTarget presentMoviePlayerViewControllerAnimated:self.player];
    }
}

//Returns whether current column view should redraw
- (BOOL)shouldDrawRect:(CGRect)rect {
//    BOOL shouldDraw = YES;
//    CTEView *scrollView = (CTEView *)[self superview];
//    CGRect scrollBounds = [scrollView bounds];
//    CGRect selfFrame = [self frame];
//    CGRect visibleScrollRect = CGRectMake(scrollBounds.origin.x, scrollBounds.origin.y,
//                                          scrollBounds.size.width, scrollBounds.size.height);
//    BOOL intersects = CGRectIntersectsRect(visibleScrollRect, selfFrame);
//    
//    //determine if it's the page before or page after the visible content
//    CGFloat visibleOriginX = visibleScrollRect.origin.x;
//    CGFloat pageWidth = scrollBounds.size.width;
//    CGFloat originX = selfFrame.origin.x;
//    CGFloat pageBeforeOriginX = visibleOriginX - pageWidth;
//    CGFloat pageAfterOriginX = visibleOriginX + pageWidth;
//    BOOL isPageBefore = originX >= pageBeforeOriginX && originX < visibleOriginX;
//    BOOL isPageAfter = originX >= pageAfterOriginX && originX < (pageAfterOriginX + pageWidth);
//    
//    //don't draw if it's not visible or page before or after visible
//    if(!intersects && !(isPageBefore || isPageAfter)) {
//        shouldDraw = NO;
//    }
//    
//    return shouldDraw;
    return YES;
}

//drawing method
//only draws view if it's visible in the parent scrollview
- (void)drawRect:(CGRect)rect {
    if(![self shouldDrawRect:rect]) {
        return;
    }
    NSLog(@"CTColumnView: START drawRect");
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Flip the coordinate system
    CGFloat columnHeight = self.bounds.size.height;
    CGFloat columnWidth = self.bounds.size.width;
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, columnHeight);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    //draw text
    CTFrameDraw((__bridge CTFrameRef)ctFrame, context);
    
    //draw images
    int imageIndex = 0;
    for (NSArray *imageData in self.imagesWithMetadata) {
        UIImage* img = [imageData objectAtIndex:0];
        NSDictionary *imageMetadata = [imageData objectAtIndex:2];
        CGRect imgBounds = CGRectFromString([imageData objectAtIndex:1]);
        
        CGFloat imgWidthOffset = 0.0;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            imgWidthOffset = (columnWidth - imgBounds.size.width) / 2;
        }
        //adjustment for single-column iPhone layout
        //TODO MarkupParser should account for this...
        else {
            imgWidthOffset = ((columnWidth - imgBounds.size.width) / 2) - 20; 
        }
        CGContextTranslateCTM(context, imgWidthOffset, 0); //center image
        CGContextDrawImage(context, imgBounds, img.CGImage);
        CGRect playButtonLocation;
        
        if([imageMetadata valueForKey:@"playButtonImage"]) {
            NSLog(@"Draw PLAY BUTTON for %@", [imageMetadata valueForKey:@"fileName"]);
            UIImage *playButtonImage = [imageMetadata valueForKey:@"playButtonImage"];
            CGFloat previewImageHeight = imgBounds.size.height;
            CGFloat previewImageWidth = imgBounds.size.width;
            CGFloat playButtonHeight = playButtonImage.size.height;
            CGFloat playButtonWidth = playButtonImage.size.width;
            CGFloat playButtonOriginX = (previewImageWidth / 2) - (30); //scaled width
            CGFloat playButtonOriginY = (previewImageHeight / 2) - (30); //scaled height
            CGRect playButtonBounds = CGRectFromString(@"{{0, 0}, {60, 60}}");
            CGContextTranslateCTM(context,
                                  playButtonOriginX - (imgWidthOffset / 2),
                                  columnHeight - 60 - playButtonOriginY); //center play button image over preview image
            //TODO height measurement makes no sense...
            CGContextDrawImage(context, playButtonBounds, playButtonImage.CGImage);
            //add location to cache
            playButtonLocation = CGRectMake(playButtonOriginX, playButtonOriginY, playButtonWidth, playButtonHeight);
            NSMutableDictionary *newImageMetadata = [NSMutableDictionary dictionaryWithDictionary:imageMetadata];
            [newImageMetadata setValue:[NSValue valueWithCGRect:playButtonLocation] forKey:@"playButtonLocation"];
            NSMutableArray *newImageData = [NSMutableArray arrayWithArray:imageData];
            [newImageData replaceObjectAtIndex:2 withObject:newImageMetadata];
            [self.imagesWithMetadata replaceObjectAtIndex:imageIndex withObject:newImageData];
        }
             
        imageIndex++;
    }

    NSLog(@"CTColumnView: END drawRect");
}

@end