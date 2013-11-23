//
//  CTEContentPopoverViewController.m
//  CoreTextEBookReader
//
//  Created by David Jedeikin on 11/18/13.
//  Copyright (c) 2013 com.davidjed. All rights reserved.
//

#import "CTEContentPopoverViewController.h"
#import "CTEMarkupParser.h"
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
@synthesize selectedFont;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil selectedFont:(NSString *)fontKey {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        NSDictionary *bodyFonts = [CTEMarkupParser bodyFontDictionary];
        self.fonts = [[bodyFonts allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        self.selectedFont = fontKey;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //give font buttons a background color
    //[UIColor colorWithRed:14.0f/255 green:104.0f/255 blue: 228.0f/255 alpha:1.0f]]
    [self.fontSmallerButton setBackgroundImage:[self imageFromColor:[UIColor darkGrayColor]]
                                      forState:UIControlStateNormal];
    self.fontSmallerButton.layer.cornerRadius = 8.0;
    self.fontSmallerButton.layer.masksToBounds = YES;
    self.fontSmallerButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.fontSmallerButton.layer.borderWidth = 1;
    [self.fontLargerButton setBackgroundImage:[self imageFromColor:[UIColor darkGrayColor]]
                                     forState:UIControlStateNormal];
    self.fontLargerButton.layer.cornerRadius = 8.0;
    self.fontLargerButton.layer.masksToBounds = YES;
    self.fontLargerButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.fontLargerButton.layer.borderWidth = 1;

    //horizontal line after title
    //http://stackoverflow.com/questions/6254556/how-to-draw-a-line-in-interface-builder-in-xcode-4
    float width = self.view.bounds.size.width;
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 28, width, 1.0f)];
    line.backgroundColor = [UIColor darkGrayColor];//[UIColor colorWithRed:(200.0f/255.0f) green:(200.0f/255.0f) blue:(200.0f/255.0f) alpha:1.0f];
    line.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    line.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
    line.layer.shadowRadius = 0.5f;
    line.layer.shadowOpacity = 0.4f;
    line.layer.masksToBounds = NO;
    [self.view addSubview:line];
    
    //set selected font in picker
    [self.fontPicker setShowsSelectionIndicator:YES];
    int selectedFontIndex = [self.fonts indexOfObject:self.selectedFont];
    [self.fontPicker selectRow:selectedFontIndex inComponent:0 animated:NO];
}

//prevents popover from stretching to max height
-(CGSize)contentSizeForViewInPopover {
    return self.view.bounds.size;
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

//select font and post notification
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedFont = (NSString *)[fonts objectAtIndex:row];
    
    //TODO notificashionne
}

@end
