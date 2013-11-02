//
//  WTRImageViewController.m
//  CoreTextEBookReader
//
//  Created by djedeikin on 5/30/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import "CTEImageViewController.h"
#import "CTEMediaCache.h"

#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP 1.5

@implementation CTEImageViewController

@synthesize imagePath;
@synthesize imageScrollView;
@synthesize imageView;

//constructor with image path
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil imagePath:(NSString *)image {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        self.imagePath = image;
    }
    return self;
}

//loads in the image
- (void)viewDidLoad {
    [imageScrollView setBackgroundColor:[UIColor blackColor]];
    [imageScrollView setCanCancelContentTouches:NO];
    imageScrollView.clipsToBounds = YES; // default is NO, we want to restrict drawing within our scrollview
    imageScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    //images here are already in the cache
    UIImage *img = [[CTEMediaCache sharedMediaCache] getImage:imagePath];

    //error handling
    if (!img) {
        img = [UIImage imageNamed:@"ImageError.png"];
    }
    imageView.image = img;
    [imageView sizeToFit];
    CGSize imgSize = img.size;
    [imageScrollView setContentSize:CGSizeMake(imgSize.width, imgSize.height)];
    [imageScrollView setMinimumZoomScale: 0.5];
    [imageScrollView setMaximumZoomScale:3.0];
    [imageScrollView setScrollEnabled:YES];
    
    [super viewDidLoad];

}

//zoom handling
- (void)scrollViewDidZoom:(UIScrollView *)aScrollView {
    CGFloat offsetX = (imageScrollView.bounds.size.width > imageScrollView.contentSize.width)?
    (imageScrollView.bounds.size.width - imageScrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (imageScrollView.bounds.size.height > imageScrollView.contentSize.height)?
    (imageScrollView.bounds.size.height - imageScrollView.contentSize.height) * 0.5 : 0.0;
    imageView.center = CGPointMake(imageScrollView.contentSize.width * 0.5 + offsetX,
                                   imageScrollView.contentSize.height * 0.5 + offsetY);
}

//zoom handling
- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return imageView;
}

//close view
- (IBAction)respondToCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
