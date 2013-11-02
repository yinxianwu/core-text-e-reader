//
//  WTRImageViewController.h
//  CoreTextEBookReader
//
//  Created by djedeikin on 5/30/13.
//  Copyright (c) 2013 Holocene Press. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CTEImageViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) IBOutlet UIScrollView *imageScrollView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil imagePath:(NSString *)image;
- (IBAction)respondToCloseButton:(id)sender;

@end
