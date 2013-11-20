//
//  CTEContentPopoverViewController.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/18/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEContentPopoverViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CTEContentPopoverViewController ()

@end

@implementation CTEContentPopoverViewController

@synthesize fontSmallerButton;
@synthesize fontLargerButton;
@synthesize singleColumnButton;
@synthesize doubleColumnButton;
@synthesize fontPicker;

@synthesize fonts;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        self.fonts = [[NSArray alloc] initWithObjects:@"Palatino", @"Garamond", @"Baskerville", @"Times New Roman", nil];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //give font buttons a background color
    [self.fontSmallerButton setBackgroundImage:[self imageFromColor:[UIColor colorWithRed:14.0f/255 green:104.0f/255 blue: 228.0f/255 alpha:1.0f]]
                                      forState:UIControlStateNormal];
    self.fontSmallerButton.layer.cornerRadius = 8.0;
    self.fontSmallerButton.layer.masksToBounds = YES;
    self.fontSmallerButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.fontSmallerButton.layer.borderWidth = 1;
    [self.fontLargerButton setBackgroundImage:[self imageFromColor:[UIColor colorWithRed:14.0f/255 green:104.0f/255 blue: 228.0f/255 alpha:1.0f]]
                                     forState:UIControlStateNormal];
    self.fontLargerButton.layer.cornerRadius = 8.0;
    self.fontLargerButton.layer.masksToBounds = YES;
    self.fontLargerButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.fontLargerButton.layer.borderWidth = 1;
}

//button background
- (UIImage *) imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
#pragma mark - UIPickerView DataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [fonts count];
}

#pragma mark - UIPickerView Delegate

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 30.0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [fonts objectAtIndex:row];
}

//If the user chooses from the pickerview, it calls this function;
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    //Let's print in the console what the user had chosen;
    NSLog(@"Chosen item: %@", [fonts objectAtIndex:row]);
}

@end
